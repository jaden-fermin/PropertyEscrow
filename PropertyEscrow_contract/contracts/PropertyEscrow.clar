
;; title: PropertyEscrow
;; version: 1.0.0
;; summary: Smart contract for real estate purchase and sale escrow transactions
;; description: This contract manages escrow for property transactions, holding funds until conditions are met

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ESCROW_NOT_FOUND (err u101))
(define-constant ERR_ESCROW_ALREADY_EXISTS (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_ESCROW_NOT_PENDING (err u104))
(define-constant ERR_ESCROW_NOT_FUNDED (err u105))
(define-constant ERR_INVALID_PARTY (err u106))
(define-constant ERR_ESCROW_EXPIRED (err u107))
(define-constant ERR_ESCROW_NOT_EXPIRED (err u108))

;; data vars
;;
(define-data-var next-escrow-id uint u1)

;; data maps
;;
(define-map escrows
  { escrow-id: uint }
  {
    buyer: principal,
    seller: principal,
    agent: principal,
    property-id: (string-ascii 50),
    amount: uint,
    status: (string-ascii 20),
    created-at: uint,
    expiry-block: uint,
    conditions-met: bool
  }
)

(define-map escrow-funds
  { escrow-id: uint }
  { amount: uint }
)

;; public functions
;;

;; Create a new escrow for a property transaction
(define-public (create-escrow
    (buyer principal)
    (seller principal)
    (agent principal)
    (property-id (string-ascii 50))
    (amount uint)
    (duration-blocks uint))
  (let (
    (escrow-id (var-get next-escrow-id))
    (expiry-block (+ block-height duration-blocks))
  )
    ;; Note: For simplicity, we allow multiple escrows per property
    ;; In a production system, you might want to add additional checks

    ;; Create escrow record
    (map-set escrows
      { escrow-id: escrow-id }
      {
        buyer: buyer,
        seller: seller,
        agent: agent,
        property-id: property-id,
        amount: amount,
        status: "pending",
        created-at: block-height,
        expiry-block: expiry-block,
        conditions-met: false
      }
    )

    ;; Initialize escrow funds
    (map-set escrow-funds
      { escrow-id: escrow-id }
      { amount: u0 }
    )

    ;; Increment next escrow ID
    (var-set next-escrow-id (+ escrow-id u1))

    (ok escrow-id)
  )
)

;; Fund an escrow (buyer deposits STX)
(define-public (fund-escrow (escrow-id uint))
  (let (
    (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND))
    (required-amount (get amount escrow))
  )
    ;; Only buyer can fund the escrow
    (asserts! (is-eq tx-sender (get buyer escrow)) ERR_UNAUTHORIZED)

    ;; Check escrow is in pending status
    (asserts! (is-eq (get status escrow) "pending") ERR_ESCROW_NOT_PENDING)

    ;; Check escrow hasn't expired
    (asserts! (< block-height (get expiry-block escrow)) ERR_ESCROW_EXPIRED)

    ;; Transfer STX to contract
    (try! (stx-transfer? required-amount tx-sender (as-contract tx-sender)))

    ;; Update escrow funds
    (map-set escrow-funds
      { escrow-id: escrow-id }
      { amount: required-amount }
    )

    ;; Update escrow status
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow { status: "funded" })
    )

    (ok true)
  )
)

;; Mark conditions as met (agent function)
(define-public (mark-conditions-met (escrow-id uint))
  (let (
    (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND))
  )
    ;; Only agent can mark conditions as met
    (asserts! (is-eq tx-sender (get agent escrow)) ERR_UNAUTHORIZED)

    ;; Check escrow is funded
    (asserts! (is-eq (get status escrow) "funded") ERR_ESCROW_NOT_FUNDED)

    ;; Update conditions-met flag
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow { conditions-met: true })
    )

    (ok true)
  )
)

;; Release funds to seller (when conditions are met)
(define-public (release-funds (escrow-id uint))
  (let (
    (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND))
    (funds (unwrap! (map-get? escrow-funds { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND))
    (amount (get amount funds))
  )
    ;; Only agent can release funds
    (asserts! (is-eq tx-sender (get agent escrow)) ERR_UNAUTHORIZED)

    ;; Check escrow is funded
    (asserts! (is-eq (get status escrow) "funded") ERR_ESCROW_NOT_FUNDED)

    ;; Check conditions are met
    (asserts! (get conditions-met escrow) ERR_UNAUTHORIZED)

    ;; Transfer funds to seller
    (try! (as-contract (stx-transfer? amount tx-sender (get seller escrow))))

    ;; Update escrow status
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow { status: "completed" })
    )

    ;; Clear escrow funds
    (map-set escrow-funds
      { escrow-id: escrow-id }
      { amount: u0 }
    )

    (ok true)
  )
)

;; Cancel escrow and refund buyer (if conditions not met and expired)
(define-public (cancel-escrow (escrow-id uint))
  (let (
    (escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND))
    (funds (unwrap! (map-get? escrow-funds { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND))
    (amount (get amount funds))
  )
    ;; Only buyer or agent can cancel
    (asserts! (or (is-eq tx-sender (get buyer escrow))
                  (is-eq tx-sender (get agent escrow))) ERR_UNAUTHORIZED)

    ;; Check escrow is funded
    (asserts! (is-eq (get status escrow) "funded") ERR_ESCROW_NOT_FUNDED)

    ;; Check escrow has expired OR conditions are not met
    (asserts! (or (>= block-height (get expiry-block escrow))
                  (not (get conditions-met escrow))) ERR_ESCROW_NOT_EXPIRED)

    ;; Refund buyer if there are funds
    (if (> amount u0)
      (try! (as-contract (stx-transfer? amount tx-sender (get buyer escrow))))
      true
    )

    ;; Update escrow status
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow { status: "cancelled" })
    )

    ;; Clear escrow funds
    (map-set escrow-funds
      { escrow-id: escrow-id }
      { amount: u0 }
    )

    (ok true)
  )
)

;; read only functions
;;

;; Get escrow details by ID
(define-read-only (get-escrow (escrow-id uint))
  (map-get? escrows { escrow-id: escrow-id })
)

;; Get escrow funds by ID
(define-read-only (get-escrow-funds (escrow-id uint))
  (map-get? escrow-funds { escrow-id: escrow-id })
)

;; Get next escrow ID
(define-read-only (get-next-escrow-id)
  (var-get next-escrow-id)
)

;; Get escrow status
(define-read-only (get-escrow-status (escrow-id uint))
  (match (map-get? escrows { escrow-id: escrow-id })
    escrow (some (get status escrow))
    none
  )
)

;; Check if escrow is expired
(define-read-only (is-escrow-expired (escrow-id uint))
  (match (map-get? escrows { escrow-id: escrow-id })
    escrow (>= block-height (get expiry-block escrow))
    false
  )
)

;; private functions
;;
