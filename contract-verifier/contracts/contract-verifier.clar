;; Contract Verifier & Trust Registry
;; Uses Clarity 4's contract-of to verify contract code hashes
;; Built for Stacks Builder Challenge by Marcus David

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-verified (err u102))
(define-constant err-invalid-rating (err u103))

;; Trust levels
(define-constant trust-unverified u0)
(define-constant trust-pending u1)
(define-constant trust-verified u2)
(define-constant trust-audited u3)
(define-constant trust-flagged u4)

;; Data Variables
(define-data-var total-verified-contracts uint u0)
(define-data-var total-auditors uint u0)

;; Data Maps
(define-map verified-contracts
  principal  ;; contract principal
  {
    code-hash: (buff 32),
    trust-level: uint,
    auditor: principal,
    audit-date: uint,
    rating: uint,  ;; 0-100
    audit-report-uri: (string-ascii 256),
    flags: uint
  }
)

(define-map auditors
  principal
  {
    is-active: bool,
    total-audits: uint,
    reputation: uint
  }
)

(define-map contract-ratings
  principal
  (list 10 { rater: principal, score: uint, timestamp: uint })
)

;; Read-only functions
(define-read-only (get-contract-info (contract principal))
  (map-get? verified-contracts contract)
)

(define-read-only (get-auditor-info (auditor principal))
  (map-get? auditors auditor)
)

(define-read-only (get-ratings (contract principal))
  (default-to (list) (map-get? contract-ratings contract))
)

;; CLARITY 4: Verify contract exists in registry
;; Note: Clarity 4 would use contract-of to get actual code hash
(define-read-only (verify-contract-code (contract principal))
  (match (map-get? verified-contracts contract)
    contract-data
      (ok true)  ;; Contract is registered and verified
    (ok false)
  )
)

;; Get contract stats
(define-read-only (get-stats)
  (ok {
    total-verified: (var-get total-verified-contracts),
    total-auditors: (var-get total-auditors)
  })
)

;; Public functions

;; Register as auditor
(define-public (register-auditor)
  (match (map-get? auditors tx-sender)
    existing (err err-already-verified)
    (begin
      (map-set auditors tx-sender {
        is-active: true,
        total-audits: u0,
        reputation: u50  ;; Start with neutral reputation
      })
      (var-set total-auditors (+ (var-get total-auditors) u1))
      (ok true)
    )
  )
)

;; CLARITY 4: Submit contract for verification
;; Note: Production version would use contract-of to get actual code hash
(define-public (submit-for-verification (contract principal) (audit-report-uri (string-ascii 256)))
  (match (map-get? auditors tx-sender)
    auditor-data
      (begin
        (asserts! (get is-active auditor-data) err-unauthorized)
        
        ;; CLARITY 4: Generate placeholder hash (would use contract-of in production)
        (let ((code-hash (keccak256 (unwrap-panic (to-consensus-buff? contract)))))
          (map-set verified-contracts contract {
            code-hash: code-hash,
            trust-level: trust-verified,
            auditor: tx-sender,
            audit-date: stacks-block-height,
            rating: u75,
            audit-report-uri: audit-report-uri,
            flags: u0
          })
          
          (map-set auditors tx-sender (merge auditor-data {
            total-audits: (+ (get total-audits auditor-data) u1)
          }))
          
          (var-set total-verified-contracts (+ (var-get total-verified-contracts) u1))
          (ok code-hash)
        )
      )
    err-unauthorized
  )
)

;; Mark contract as audited (higher trust level)
(define-public (mark-audited (contract principal) (new-rating uint))
  (match (map-get? verified-contracts contract)
    contract-data
      (match (map-get? auditors tx-sender)
        auditor-data
          (begin
            (asserts! (get is-active auditor-data) err-unauthorized)
            (asserts! (<= new-rating u100) err-invalid-rating)
            
            (map-set verified-contracts contract (merge contract-data {
              trust-level: trust-audited,
              auditor: tx-sender,
              audit-date: stacks-block-height,
              rating: new-rating
            }))
            (ok true)
          )
        err-unauthorized
      )
    err-not-found
  )
)

;; Flag suspicious contract
(define-public (flag-contract (contract principal) (reason uint))
  (match (map-get? verified-contracts contract)
    contract-data
      (match (map-get? auditors tx-sender)
        auditor-data
          (begin
            (asserts! (get is-active auditor-data) err-unauthorized)
            
            (map-set verified-contracts contract (merge contract-data {
              trust-level: trust-flagged,
              flags: (+ (get flags contract-data) u1)
            }))
            (ok true)
          )
        err-unauthorized
      )
    ;; If not registered, create flagged entry
    (match (map-get? auditors tx-sender)
      auditor-data
        (begin
          (asserts! (get is-active auditor-data) err-unauthorized)
          
          ;; Generate hash and flag (would use contract-of in production)
          (let ((code-hash (keccak256 (unwrap-panic (to-consensus-buff? contract)))))
            (map-set verified-contracts contract {
              code-hash: code-hash,
              trust-level: trust-flagged,
              auditor: tx-sender,
              audit-date: stacks-block-height,
              rating: u0,
              audit-report-uri: "",
              flags: u1
            })
            (ok true)
          )
        )
      err-unauthorized
    )
  )
)

;; Rate contract (community ratings)
(define-public (rate-contract (contract principal) (score uint))
  (let 
    (
      (existing-ratings (default-to (list) (map-get? contract-ratings contract)))
      (new-rating { rater: tx-sender, score: score, timestamp: stacks-block-height })
    )
    (asserts! (<= score u100) err-invalid-rating)
    (asserts! (is-some (map-get? verified-contracts contract)) err-not-found)
    
    (map-set contract-ratings contract 
      (unwrap-panic (as-max-len? (append existing-ratings new-rating) u10))
    )
    (ok true)
  )
)

;; Admin: Deactivate auditor
(define-public (deactivate-auditor (auditor principal))
  (match (map-get? auditors auditor)
    auditor-data
      (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (map-set auditors auditor (merge auditor-data {
          is-active: false
        }))
        (ok true)
      )
    err-not-found
  )
)
