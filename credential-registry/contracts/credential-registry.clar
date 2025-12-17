;; Credential Registry - On-Chain Credentials and Certificates
;; Issue, verify, and revoke digital credentials

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-issued (err u103))
(define-constant err-revoked (err u104))
(define-constant err-expired (err u105))
(define-constant err-not-issuer (err u106))

;; Data Variables
(define-data-var credential-nonce uint u0)

;; Credential Types
(define-constant type-certificate u1)
(define-constant type-license u2)
(define-constant type-badge u3)
(define-constant type-degree u4)

;; Status
(define-constant status-active u1)
(define-constant status-revoked u2)
(define-constant status-expired u3)

;; Data Maps
(define-map issuers
  { issuer: principal }
  {
    name: (string-ascii 64),
    verified: bool,
    credentials-issued: uint,
    reputation: uint,
    registered-at: uint
  }
)

(define-map credentials
  { credential-id: uint }
  {
    holder: principal,
    issuer: principal,
    credential-type: uint,
    title: (string-ascii 128),
    metadata-uri: (string-ascii 256),
    issued-at: uint,
    expires-at: (optional uint),
    status: uint,
    verification-count: uint
  }
)

(define-map holder-credentials
  { holder: principal, index: uint }
  { credential-id: uint }
)

(define-map holder-credential-count
  { holder: principal }
  { count: uint }
)

(define-map verifications
  { credential-id: uint, verifier: principal }
  {
    verified: bool,
    verified-at: uint,
    notes: (optional (string-ascii 256))
  }
)

;; Read-Only Functions
(define-read-only (get-issuer (issuer principal))
  (map-get? issuers { issuer: issuer })
)

(define-read-only (is-verified-issuer (issuer principal))
  (match (get-issuer issuer)
    info (get verified info)
    false
  )
)

(define-read-only (get-credential (credential-id uint))
  (map-get? credentials { credential-id: credential-id })
)

(define-read-only (is-credential-valid (credential-id uint))
  (match (get-credential credential-id)
    cred
      (and
        (is-eq (get status cred) status-active)
        (match (get expires-at cred)
          expiry (<= block-height expiry)
          true
        )
      )
    false
  )
)

(define-read-only (get-holder-credential-count (holder principal))
  (default-to
    { count: u0 }
    (map-get? holder-credential-count { holder: holder })
  )
)

(define-read-only (get-holder-credential-id (holder principal) (index uint))
  (map-get? holder-credentials { holder: holder, index: index })
)

(define-read-only (get-verification (credential-id uint) (verifier principal))
  (map-get? verifications { credential-id: credential-id, verifier: verifier })
)

;; Public Functions
(define-public (register-issuer (name (string-ascii 64)))
  (begin
    (map-set issuers
      { issuer: tx-sender }
      {
        name: name,
        verified: false,
        credentials-issued: u0,
        reputation: u0,
        registered-at: block-height
      }
    )
    
    (ok true)
  )
)

(define-public (verify-issuer (issuer principal))
  (let (
    (issuer-info (unwrap! (get-issuer issuer) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set issuers
      { issuer: issuer }
      (merge issuer-info { verified: true })
    )
    
    (ok true)
  )
)

(define-public (issue-credential
    (holder principal)
    (credential-type uint)
    (title (string-ascii 128))
    (metadata-uri (string-ascii 256))
    (expires-at (optional uint))
  )
  (let (
    (credential-id (+ (var-get credential-nonce) u1))
    (issuer-info (unwrap! (get-issuer tx-sender) err-not-issuer))
    (holder-count (get-holder-credential-count holder))
  )
    (map-set credentials
      { credential-id: credential-id }
      {
        holder: holder,
        issuer: tx-sender,
        credential-type: credential-type,
        title: title,
        metadata-uri: metadata-uri,
        issued-at: block-height,
        expires-at: expires-at,
        status: status-active,
        verification-count: u0
      }
    )
    
    (map-set holder-credentials
      { holder: holder, index: (get count holder-count) }
      { credential-id: credential-id }
    )
    
    (map-set holder-credential-count
      { holder: holder }
      { count: (+ (get count holder-count) u1) }
    )
    
    (map-set issuers
      { issuer: tx-sender }
      (merge issuer-info {
        credentials-issued: (+ (get credentials-issued issuer-info) u1)
      })
    )
    
    (var-set credential-nonce credential-id)
    (ok credential-id)
  )
)

(define-public (revoke-credential (credential-id uint))
  (let (
    (cred (unwrap! (get-credential credential-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get issuer cred)) err-unauthorized)
    (asserts! (is-eq (get status cred) status-active) err-revoked)
    
    (map-set credentials
      { credential-id: credential-id }
      (merge cred { status: status-revoked })
    )
    
    (ok true)
  )
)

(define-public (verify-credential (credential-id uint) (notes (optional (string-ascii 256))))
  (let (
    (cred (unwrap! (get-credential credential-id) err-not-found))
  )
    (asserts! (is-credential-valid credential-id) err-revoked)
    
    (map-set verifications
      { credential-id: credential-id, verifier: tx-sender }
      {
        verified: true,
        verified-at: block-height,
        notes: notes
      }
    )
    
    (map-set credentials
      { credential-id: credential-id }
      (merge cred {
        verification-count: (+ (get verification-count cred) u1)
      })
    )
    
    (ok true)
  )
)

(define-public (transfer-credential (credential-id uint) (new-holder principal))
  (let (
    (cred (unwrap! (get-credential credential-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get holder cred)) err-unauthorized)
    (asserts! (is-credential-valid credential-id) err-revoked)
    
    (map-set credentials
      { credential-id: credential-id }
      (merge cred { holder: new-holder })
    )
    
    (ok true)
  )
)

(define-public (update-issuer-reputation (issuer principal) (reputation-delta int))
  (let (
    (issuer-info (unwrap! (get-issuer issuer) err-not-found))
    (current-rep (get reputation issuer-info))
    (new-rep (if (< reputation-delta 0)
      (if (> (to-uint (- reputation-delta)) current-rep)
        u0
        (- current-rep (to-uint (- reputation-delta)))
      )
      (+ current-rep (to-uint reputation-delta))
    ))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set issuers
      { issuer: issuer }
      (merge issuer-info { reputation: new-rep })
    )
    
    (ok new-rep)
  )
)
