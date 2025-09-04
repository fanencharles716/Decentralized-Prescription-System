# 💊 RxChain - Decentralized Prescription System

A secure blockchain-based prescription management system that prevents abuse and ensures patient safety through immutable record-keeping and multi-party verification.

## 🎯 Overview

RxChain leverages blockchain technology to create a transparent, secure, and tamper-proof prescription tracking system. The platform connects doctors, patients, and pharmacies in a decentralized network where prescriptions cannot be duplicated, forged, or abused.

## ✨ Key Features

- 🔒 **Secure Prescription Issuance**: Only registered doctors can issue prescriptions
- 👤 **Patient Registration**: Secure patient identity verification and medical ID tracking
- 🏥 **Pharmacy Authorization**: Verified pharmacies can fill prescriptions with full audit trails
- ⏰ **Expiration Management**: Time-bound prescriptions prevent outdated medication dispensing
- 🔄 **Refill Tracking**: Controlled refill limits prevent over-dispensing
- 📊 **Prescription History**: Complete medication history for patients and healthcare providers
- 🚨 **Controlled Substance Monitoring**: Special tracking for controlled medications
- ✅ **Multi-party Verification**: Patients, doctors, and pharmacies all have appropriate access levels

## 🏗️ Contract Architecture

### Data Structures

- **Patients**: Name, age, medical ID, registration timestamp
- **Prescriptions**: Complete prescription details including doctor, patient, medication, dosage, expiration
- **Prescription Fills**: Pharmacy fill records with timestamps and pharmacist notes
- **Authorization Maps**: Separate registries for doctors and pharmacies

### Access Control

- **Contract Owner**: Can register doctors and pharmacies
- **Doctors**: Can issue and revoke prescriptions
- **Pharmacies**: Can fill valid prescriptions
- **Patients**: Can view their prescription history and transfer prescriptions

## 🚀 Usage Instructions

### Initial Setup

1. **Register Healthcare Providers**
```clarity
;; Register a doctor (only contract owner)
(contract-call? .RxChain register-doctor 'SP1234...DOCTOR)

;; Register a pharmacy (only contract owner)  
(contract-call? .RxChain register-pharmacy 'SP5678...PHARMACY)
```

2. **Patient Registration**
```clarity
;; Patients self-register
(contract-call? .RxChain register-patient "John Smith" u35 "MED123456")
```

### Prescription Workflow

3. **Doctor Issues Prescription**
```clarity
(contract-call? .RxChain issue-prescription
  'SP9012...PATIENT     ;; patient principal
  "Amoxicillin 500mg"   ;; medication
  "500mg twice daily"   ;; dosage
  u30                   ;; quantity (30 pills)
  u2                    ;; refills allowed
  u1440                 ;; validity (1440 blocks ≈ 10 days)
  false                 ;; not controlled substance
  "Take with food"      ;; instructions
)
```

4. **Pharmacy Fills Prescription**
```clarity
(contract-call? .RxChain fill-prescription
  u1                    ;; prescription ID
  u30                   ;; quantity filled
  "Verified ID"         ;; pharmacist notes
)
```

5. **Patient Transfer Prescription**
```clarity
;; Transfer to different pharmacy
(contract-call? .RxChain transfer-prescription u1 'SP3456...NEW-PHARMACY)
```

### Query Functions

6. **Check Prescription Details**
```clarity
;; Get prescription information
(contract-call? .RxChain get-prescription u1)

;; Check if prescription can be refilled
(contract-call? .RxChain can-refill u1)

;; Get remaining refills
(contract-call? .RxChain get-refills-remaining u1)
```

7. **Patient History**
```clarity
;; Get patient's prescription history
(contract-call? .RxChain get-prescription-history 'SP1234...PATIENT)

;; Get controlled substance prescriptions
(contract-call? .RxChain get-controlled-prescriptions 'SP1234...PATIENT)
```

8. **Prescription Status**
```clarity
;; Check prescription status
(contract-call? .RxChain get-prescription-status u1)
;; Returns: "active", "expired", "completed", or "not-found"
```

## 🛡️ Security Features

- **Authorization Checks**: Multi-level access control for all operations
- **Expiration Enforcement**: Automatic expiration prevents stale prescriptions
- **Refill Limits**: Built-in safeguards against over-dispensing
- **Immutable Records**: Blockchain ensures prescription history cannot be altered
- **Controlled Substance Tracking**: Special monitoring for regulated medications

## 📋 Error Codes

| Code | Description |
|------|-------------|
| u100 | Not authorized |
| u101 | Prescription not found |
| u102 | Already filled |
| u103 | Prescription expired |
| u104 | Invalid quantity |
| u105 | Not a registered doctor |
| u106 | Not a registered pharmacy |
| u107 | Patient not found |
| u108 | Refill limit exceeded |
| u109 | Invalid input |

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
clarinet test
```

Check contract compilation:

```bash
clarinet check
```

## 🔧 Development

Built with [Clarinet](https://github.com/hirosystems/clarinet) for Stacks blockchain development.

### Prerequisites
- Clarinet CLI
- Node.js (for testing framework)

### Local Development
```bash
# Check contract syntax
clarinet check

# Run tests
clarinet test

# Deploy to testnet
clarinet deploy --testnet
```

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions welcome! Please ensure all tests pass before submitting PRs.

---

*🔗 Built on Stacks blockchain for maximum security and decentralization*
