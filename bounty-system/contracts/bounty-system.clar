;; Bounty System - Task Bounties with Milestone Verification
;; Post tasks with rewards, submit work, and verify completion

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-already-claimed (err u104))
(define-constant err-not-completed (err u105))
(define-constant err-already-assigned (err u106))

;; Data Variables
(define-data-var bounty-nonce uint u0)
(define-data-var platform-fee-percent uint u500) ;; 5%

;; Bounty Status
(define-constant status-open u1)
(define-constant status-assigned u2)
(define-constant status-submitted u3)
(define-constant status-completed u4)
(define-constant status-cancelled u5)

;; Data Maps
(define-map bounties
  { bounty-id: uint }
  {
    creator: principal,
    reward: uint,
    title: (string-ascii 256),
    hunter: (optional principal),
    status: uint,
    created-at: uint,
    deadline: uint,
    submission: (optional (string-ascii 512))
  }
)

(define-map bounty-milestones
  { bounty-id: uint, milestone-id: uint }
  {
    description: (string-ascii 256),
    percentage: uint,
    completed: bool
  }
)

(define-map user-stats
  { user: principal }
  {
    bounties-created: uint,
    bounties-completed: uint,
    total-earned: uint,
    reputation-score: uint
  }
)

;; Read-Only Functions
(define-read-only (get-bounty (bounty-id uint))
  (map-get? bounties { bounty-id: bounty-id })
)

(define-read-only (get-milestone (bounty-id uint) (milestone-id uint))
  (map-get? bounty-milestones { bounty-id: bounty-id, milestone-id: milestone-id })
)

(define-read-only (get-user-stats (user principal))
  (default-to
    { bounties-created: u0, bounties-completed: u0, total-earned: u0, reputation-score: u0 }
    (map-get? user-stats { user: user })
  )
)

(define-read-only (get-platform-fee)
  (ok (var-get platform-fee-percent))
)

;; Public Functions
(define-public (create-bounty (reward uint) (title (string-ascii 256)) (deadline uint))
  (let (
    (bounty-id (+ (var-get bounty-nonce) u1))
    (creator-stats (get-user-stats tx-sender))
  )
    (asserts! (> reward u0) err-invalid-amount)
    (asserts! (> deadline block-height) err-invalid-amount)
    
    (map-set bounties
      { bounty-id: bounty-id }
      {
        creator: tx-sender,
        reward: reward,
        title: title,
        hunter: none,
        status: status-open,
        created-at: block-height,
        deadline: deadline,
        submission: none
      }
    )
    
    (map-set user-stats
      { user: tx-sender }
      (merge creator-stats {
        bounties-created: (+ (get bounties-created creator-stats) u1)
      })
    )
    
    (var-set bounty-nonce bounty-id)
    (ok bounty-id)
  )
)

(define-public (claim-bounty (bounty-id uint))
  (let (
    (bounty (unwrap! (get-bounty bounty-id) err-not-found))
  )
    (asserts! (is-eq (get status bounty) status-open) err-already-assigned)
    (asserts! (< block-height (get deadline bounty)) err-not-completed)
    
    (map-set bounties
      { bounty-id: bounty-id }
      (merge bounty {
        hunter: (some tx-sender),
        status: status-assigned
      })
    )
    
    (ok true)
  )
)

(define-public (submit-work (bounty-id uint) (submission (string-ascii 512)))
  (let (
    (bounty (unwrap! (get-bounty bounty-id) err-not-found))
  )
    (asserts! (is-eq (get status bounty) status-assigned) err-unauthorized)
    (asserts! (is-eq (some tx-sender) (get hunter bounty)) err-unauthorized)
    (asserts! (< block-height (get deadline bounty)) err-not-completed)
    
    (map-set bounties
      { bounty-id: bounty-id }
      (merge bounty {
        submission: (some submission),
        status: status-submitted
      })
    )
    
    (ok true)
  )
)

(define-public (approve-bounty (bounty-id uint))
  (let (
    (bounty (unwrap! (get-bounty bounty-id) err-not-found))
    (hunter (unwrap! (get hunter bounty) err-unauthorized))
    (platform-fee (/ (* (get reward bounty) (var-get platform-fee-percent)) u10000))
    (hunter-payment (- (get reward bounty) platform-fee))
    (hunter-stats (get-user-stats hunter))
  )
    (asserts! (is-eq tx-sender (get creator bounty)) err-unauthorized)
    (asserts! (is-eq (get status bounty) status-submitted) err-not-completed)
    
    (map-set bounties
      { bounty-id: bounty-id }
      (merge bounty { status: status-completed })
    )
    
    (map-set user-stats
      { user: hunter }
      (merge hunter-stats {
        bounties-completed: (+ (get bounties-completed hunter-stats) u1),
        total-earned: (+ (get total-earned hunter-stats) hunter-payment),
        reputation-score: (+ (get reputation-score hunter-stats) u10)
      })
    )
    
    (ok hunter-payment)
  )
)

(define-public (cancel-bounty (bounty-id uint))
  (let (
    (bounty (unwrap! (get-bounty bounty-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get creator bounty)) err-unauthorized)
    (asserts! (is-eq (get status bounty) status-open) err-already-assigned)
    
    (map-set bounties
      { bounty-id: bounty-id }
      (merge bounty { status: status-cancelled })
    )
    
    (ok true)
  )
)

(define-public (add-milestone (bounty-id uint) (milestone-id uint) (description (string-ascii 256)) (percentage uint))
  (let (
    (bounty (unwrap! (get-bounty bounty-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get creator bounty)) err-unauthorized)
    
    (map-set bounty-milestones
      { bounty-id: bounty-id, milestone-id: milestone-id }
      {
        description: description,
        percentage: percentage,
        completed: false
      }
    )
    
    (ok true)
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set platform-fee-percent new-fee)
    (ok true)
  )
)
