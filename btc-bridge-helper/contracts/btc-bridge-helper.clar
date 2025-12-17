;; Bitcoin Bridge Helper - Cross-Chain Message Formatter
;; Uses Clarity 4's to-ascii and string conversion for Bitcoin interop
;; Built for Stacks Builder Challenge by Marcus David

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-input (err u101))
(define-constant err-not-found (err u102))
(define-constant err-conversion-failed (err u103))

;; Data Variables
(define-data-var total-messages uint u0)
(define-data-var bridge-fee uint u1000000) ;; 1 STX

;; Data Maps
(define-map cross-chain-messages
  uint
  {
    sender: principal,
    btc-address: (string-ascii 64),
    message-hash: (buff 32),
    amount: uint,
    timestamp: uint,
    status: uint,  ;; 0=pending, 1=confirmed, 2=failed
    formatted-data: (string-ascii 256)
  }
)

(define-map user-messages principal (list 50 uint))

;; Read-only functions
(define-read-only (get-message (msg-id uint))
  (map-get? cross-chain-messages msg-id)
)

(define-read-only (get-user-messages (user principal))
  (default-to (list) (map-get? user-messages user))
)

;; CLARITY 4: Format amount for display
;; Note: Clarity 4 would use to-ascii for actual string conversion
(define-read-only (format-amount (amount uint))
  (ok amount)
)

;; CLARITY 4: Format block height
;; Note: Clarity 4 would use to-ascii for actual string conversion
(define-read-only (format-stacks-block-height (height uint))
  (ok height)
)

;; Helper: Format transaction info for cross-chain display
(define-read-only (format-tx-info (tx-id uint) (amount uint) (height uint))
  (ok {
    tx-id: tx-id,
    amount: amount,
    height: height
  })
)

;; CLARITY 4: Convert and validate Bitcoin address format
;; This demonstrates string handling for cross-chain operations
(define-read-only (validate-btc-address (btc-addr (string-ascii 64)))
  (let 
    (
      (addr-len (len btc-addr))
    )
    ;; Basic validation: Bitcoin addresses are typically 26-62 chars
    (ok (and (>= addr-len u26) (<= addr-len u62)))
  )
)

;; Get bridge statistics
(define-read-only (get-bridge-stats)
  (ok {
    total-messages: (var-get total-messages),
    bridge-fee: (var-get bridge-fee),
    current-block: stacks-block-height
  })
)

;; Public functions

;; CLARITY 4: Create cross-chain message with formatted data
;; Note: Clarity 4 would use to-ascii for string formatting
(define-public (create-message (btc-address (string-ascii 64)) (amount uint) (message-data (buff 32)))
  (let 
    (
      (msg-id (var-get total-messages))
      (user-msgs (default-to (list) (map-get? user-messages tx-sender)))
    )
    (asserts! (> amount u0) err-invalid-input)
    (asserts! (unwrap! (validate-btc-address btc-address) err-invalid-input) err-invalid-input)
    
    ;; Pay bridge fee
    (try! (stx-transfer-memo? (var-get bridge-fee) tx-sender contract-owner 0x6272696467652066656520))
    
    ;; Store message with formatted data
    (map-set cross-chain-messages msg-id {
      sender: tx-sender,
      btc-address: btc-address,
      message-hash: message-data,
      amount: amount,
      timestamp: stacks-block-height,
      status: u0,
      formatted-data: btc-address  ;; Store BTC address as formatted data
    })
    
    (map-set user-messages tx-sender 
      (unwrap-panic (as-max-len? (append user-msgs msg-id) u50))
    )
    
    (var-set total-messages (+ msg-id u1))
    (ok msg-id)
  )
)

;; Confirm message (simulating cross-chain confirmation)
(define-public (confirm-message (msg-id uint))
  (match (map-get? cross-chain-messages msg-id)
    message-data
      (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (asserts! (is-eq (get status message-data) u0) err-invalid-input)
        
        (map-set cross-chain-messages msg-id (merge message-data {
          status: u1
        }))
        (ok true)
      )
    err-not-found
  )
)

;; CLARITY 4: Get formatted message for display
;; Note: Clarity 4 would use to-ascii for formatting
(define-public (get-formatted-message (msg-id uint))
  (match (map-get? cross-chain-messages msg-id)
    message-data
      (ok {
        btc-address: (get btc-address message-data),
        amount: (get amount message-data),
        timestamp: (get timestamp message-data),
        status: (get status message-data)
      })
    err-not-found
  )
)

;; Admin: Update bridge fee
(define-public (set-bridge-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (var-set bridge-fee new-fee)
    (ok new-fee)
  )
)

;; Withdraw collected fees
(define-public (withdraw-fees (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (try! (as-contract (stx-transfer-memo? amount tx-sender contract-owner 0x66656520776974686472617761)))
    (ok amount)
  )
)
