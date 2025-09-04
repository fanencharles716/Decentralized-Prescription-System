;; title: RxChain
;; version: 1.0.0
;; summary: Decentralized Prescription Management System
;; description: Secure prescription tracking preventing abuse and ensuring patient safety

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PRESCRIPTION-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-FILLED (err u102))
(define-constant ERR-PRESCRIPTION-EXPIRED (err u103))
(define-constant ERR-INVALID-QUANTITY (err u104))
(define-constant ERR-NOT-DOCTOR (err u105))
(define-constant ERR-NOT-PHARMACY (err u106))
(define-constant ERR-PATIENT-NOT-FOUND (err u107))
(define-constant ERR-REFILL-LIMIT-EXCEEDED (err u108))
(define-constant ERR-INVALID-INPUT (err u109))

(define-data-var prescription-counter uint u0)

(define-map doctors principal bool)
(define-map pharmacies principal bool)
(define-map patients principal 
  {
    name: (string-ascii 50),
    age: uint,
    medical-id: (string-ascii 20),
    registered-at: uint
  }
)

(define-map prescriptions uint
  {
    doctor: principal,
    patient: principal,
    medication: (string-ascii 100),
    dosage: (string-ascii 50),
    quantity: uint,
    refills-allowed: uint,
    refills-used: uint,
    issued-at: uint,
    expires-at: uint,
    is-controlled: bool,
    instructions: (string-ascii 200)
  }
)

(define-map prescription-fills uint
  {
    prescription-id: uint,
    pharmacy: principal,
    quantity-filled: uint,
    filled-at: uint,
    pharmacist-notes: (string-ascii 100)
  }
)

(define-map fill-counter uint uint)

(define-public (register-doctor (doctor principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set doctors doctor true))
  )
)

(define-public (register-pharmacy (pharmacy principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set pharmacies pharmacy true))
  )
)

(define-public (register-patient (name (string-ascii 50)) (age uint) (medical-id (string-ascii 20)))
  (begin
    (asserts! (> age u0) ERR-INVALID-INPUT)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len medical-id) u0) ERR-INVALID-INPUT)
    (ok (map-set patients tx-sender
      {
        name: name,
        age: age,
        medical-id: medical-id,
        registered-at: stacks-block-height
      }
    ))
  )
)

(define-public (issue-prescription 
  (patient principal)
  (medication (string-ascii 100))
  (dosage (string-ascii 50))
  (quantity uint)
  (refills-allowed uint)
  (validity-blocks uint)
  (is-controlled bool)
  (instructions (string-ascii 200))
)
  (let 
    (
      (prescription-id (+ (var-get prescription-counter) u1))
      (current-height stacks-block-height)
    )
    (asserts! (default-to false (map-get? doctors tx-sender)) ERR-NOT-DOCTOR)
    (asserts! (is-some (map-get? patients patient)) ERR-PATIENT-NOT-FOUND)
    (asserts! (> quantity u0) ERR-INVALID-QUANTITY)
    (asserts! (> (len medication) u0) ERR-INVALID-INPUT)
    (asserts! (> validity-blocks u0) ERR-INVALID-INPUT)
    
    (map-set prescriptions prescription-id
      {
        doctor: tx-sender,
        patient: patient,
        medication: medication,
        dosage: dosage,
        quantity: quantity,
        refills-allowed: refills-allowed,
        refills-used: u0,
        issued-at: current-height,
        expires-at: (+ current-height validity-blocks),
        is-controlled: is-controlled,
        instructions: instructions
      }
    )
    (var-set prescription-counter prescription-id)
    (ok prescription-id)
  )
)

(define-public (fill-prescription 
  (prescription-id uint)
  (quantity-to-fill uint)
  (pharmacist-notes (string-ascii 100))
)
  (let
    (
      (prescription (unwrap! (map-get? prescriptions prescription-id) ERR-PRESCRIPTION-NOT-FOUND))
      (current-height stacks-block-height)
      (fill-id (+ (default-to u0 (map-get? fill-counter prescription-id)) u1))
    )
    (asserts! (default-to false (map-get? pharmacies tx-sender)) ERR-NOT-PHARMACY)
    (asserts! (< current-height (get expires-at prescription)) ERR-PRESCRIPTION-EXPIRED)
    (asserts! (> quantity-to-fill u0) ERR-INVALID-QUANTITY)
    (asserts! (<= quantity-to-fill (get quantity prescription)) ERR-INVALID-QUANTITY)
    (asserts! (< (get refills-used prescription) (get refills-allowed prescription)) ERR-REFILL-LIMIT-EXCEEDED)

    (map-set prescription-fills fill-id
      {
        prescription-id: prescription-id,
        pharmacy: tx-sender,
        quantity-filled: quantity-to-fill,
        filled-at: current-height,
        pharmacist-notes: pharmacist-notes
      }
    )
    
    (map-set prescriptions prescription-id
      (merge prescription { refills-used: (+ (get refills-used prescription) u1) })
    )
    
    (map-set fill-counter prescription-id fill-id)
    (ok fill-id)
  )
)

(define-public (transfer-prescription (prescription-id uint) (new-pharmacy principal))
  (let
    (
      (prescription (unwrap! (map-get? prescriptions prescription-id) ERR-PRESCRIPTION-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get patient prescription)) ERR-NOT-AUTHORIZED)
    (asserts! (default-to false (map-get? pharmacies new-pharmacy)) ERR-NOT-PHARMACY)
    (asserts! (< stacks-block-height (get expires-at prescription)) ERR-PRESCRIPTION-EXPIRED)
    (ok true)
  )
)

(define-public (revoke-prescription (prescription-id uint))
  (let
    (
      (prescription (unwrap! (map-get? prescriptions prescription-id) ERR-PRESCRIPTION-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get doctor prescription)) ERR-NOT-AUTHORIZED)
    
    (map-set prescriptions prescription-id
      (merge prescription { expires-at: stacks-block-height })
    )
    (ok true)
  )
)

(define-read-only (get-prescription (prescription-id uint))
  (map-get? prescriptions prescription-id)
)

(define-read-only (get-patient-info (patient principal))
  (map-get? patients patient)
)

(define-read-only (get-prescription-fills (prescription-id uint))
  (let
    (
      (total-fills (default-to u0 (map-get? fill-counter prescription-id)))
    )
    (map get-fill-details (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10))
  )
)

(define-read-only (get-fill-details (fill-id uint))
  (map-get? prescription-fills fill-id)
)

(define-read-only (is-doctor (user principal))
  (default-to false (map-get? doctors user))
)

(define-read-only (is-pharmacy (user principal))
  (default-to false (map-get? pharmacies user))
)

(define-read-only (is-prescription-valid (prescription-id uint))
  (match (map-get? prescriptions prescription-id)
    prescription (< stacks-block-height (get expires-at prescription))
    false
  )
)

(define-read-only (get-prescription-history (patient principal))
  (filter is-patient-prescription 
    (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
  )
)

(define-read-only (is-patient-prescription (prescription-id uint))
  (match (map-get? prescriptions prescription-id)
    prescription (is-eq (get patient prescription) tx-sender)
    false
  )
)

(define-read-only (can-refill (prescription-id uint))
  (match (map-get? prescriptions prescription-id)
    prescription 
      (and 
        (< (get refills-used prescription) (get refills-allowed prescription))
        (< stacks-block-height (get expires-at prescription))
      )
    false
  )
)

(define-read-only (get-refills-remaining (prescription-id uint))
  (match (map-get? prescriptions prescription-id)
    prescription (- (get refills-allowed prescription) (get refills-used prescription))
    u0
  )
)

(define-read-only (get-prescription-count)
  (var-get prescription-counter)
)

(define-read-only (get-controlled-prescriptions (patient principal))
  (filter is-controlled-prescription-for-patient
    (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
  )
)

(define-read-only (is-controlled-prescription-for-patient (prescription-id uint))
  (match (map-get? prescriptions prescription-id)
    prescription 
      (and 
        (is-eq (get patient prescription) tx-sender)
        (get is-controlled prescription)
      )
    false
  )
)

(define-read-only (get-prescription-status (prescription-id uint))
  (match (map-get? prescriptions prescription-id)
    prescription
      (if (>= stacks-block-height (get expires-at prescription))
        "expired"
        (if (>= (get refills-used prescription) (get refills-allowed prescription))
          "completed"
          "active"
        )
      )
    "not-found"
  )
)

(define-read-only (verify-prescription-access (prescription-id uint) (accessor principal))
  (match (map-get? prescriptions prescription-id)
    prescription
      (or
        (is-eq accessor (get doctor prescription))
        (is-eq accessor (get patient prescription))
        (default-to false (map-get? pharmacies accessor))
      )
    false
  )
)
