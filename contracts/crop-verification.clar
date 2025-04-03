;; Crop Verification Contract
;; This contract validates the existence and quality of agricultural produce

(define-data-var admin principal tx-sender)

;; Data structures
(define-map crops
  { crop-id: uint }
  {
    farmer: principal,
    crop-type: (string-ascii 64),
    quantity: uint,
    quality-score: uint,
    verified: bool,
    timestamp: uint
  }
)

(define-map verifiers principal bool)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_VERIFIED u2)
(define-constant ERR_INVALID_CROP u3)
(define-constant ERR_NOT_VERIFIER u4)

;; Admin functions
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR_UNAUTHORIZED))
    (ok (var-set admin new-admin))
  )
)

(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR_UNAUTHORIZED))
    (ok (map-set verifiers verifier true))
  )
)

(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR_UNAUTHORIZED))
    (ok (map-set verifiers verifier false))
  )
)

;; Crop registration and verification
(define-public (register-crop (crop-id uint) (crop-type (string-ascii 64)) (quantity uint))
  (ok (map-set crops
    { crop-id: crop-id }
    {
      farmer: tx-sender,
      crop-type: crop-type,
      quantity: quantity,
      quality-score: u0,
      verified: false,
      timestamp: block-height
    }
  ))
)

(define-public (verify-crop (crop-id uint) (quality-score uint))
  (let (
    (crop (unwrap! (map-get? crops { crop-id: crop-id }) (err ERR_INVALID_CROP)))
    (is-verifier (default-to false (map-get? verifiers tx-sender)))
  )
    (asserts! is-verifier (err ERR_NOT_VERIFIER))
    (asserts! (not (get verified crop)) (err ERR_ALREADY_VERIFIED))

    (ok (map-set crops
      { crop-id: crop-id }
      (merge crop {
        quality-score: quality-score,
        verified: true,
        timestamp: block-height
      })
    ))
  )
)

;; Read-only functions
(define-read-only (get-crop (crop-id uint))
  (map-get? crops { crop-id: crop-id })
)

(define-read-only (is-crop-verified (crop-id uint))
  (match (map-get? crops { crop-id: crop-id })
    crop (get verified crop)
    false
  )
)

(define-read-only (is-verifier (address principal))
  (default-to false (map-get? verifiers address))
)

