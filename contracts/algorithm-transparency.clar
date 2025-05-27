;; Algorithm Transparency Contract
;; Ensures algorithmic decision transparency in financial systems

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_INVALID_INPUT (err u202))

(define-data-var algorithm-counter uint u0)

;; Algorithm registry
(define-map algorithms
  { algorithm-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    version: (string-ascii 20),
    institution-id: uint,
    transparency-score: uint,
    last-audit: uint,
    is-active: bool
  }
)

;; Algorithm decision logs
(define-map decision-logs
  { algorithm-id: uint, decision-id: uint }
  {
    input-hash: (buff 32),
    output-hash: (buff 32),
    timestamp: uint,
    confidence-score: uint
  }
)

(define-data-var decision-counter uint u0)

;; Register new algorithm
(define-public (register-algorithm
  (name (string-ascii 100))
  (description (string-ascii 500))
  (version (string-ascii 20))
  (institution-id uint))
  (let ((algorithm-id (+ (var-get algorithm-counter) u1)))
    (map-set algorithms
      { algorithm-id: algorithm-id }
      {
        name: name,
        description: description,
        version: version,
        institution-id: institution-id,
        transparency-score: u0,
        last-audit: block-height,
        is-active: true
      }
    )
    (var-set algorithm-counter algorithm-id)
    (ok algorithm-id)
  )
)

;; Log algorithm decision
(define-public (log-decision
  (algorithm-id uint)
  (input-hash (buff 32))
  (output-hash (buff 32))
  (confidence-score uint))
  (let ((decision-id (+ (var-get decision-counter) u1)))
    (asserts! (<= confidence-score u100) ERR_INVALID_INPUT)
    (map-set decision-logs
      { algorithm-id: algorithm-id, decision-id: decision-id }
      {
        input-hash: input-hash,
        output-hash: output-hash,
        timestamp: block-height,
        confidence-score: confidence-score
      }
    )
    (var-set decision-counter decision-id)
    (ok decision-id)
  )
)

;; Update transparency score
(define-public (update-transparency-score (algorithm-id uint) (score uint))
  (let ((algorithm (unwrap! (map-get? algorithms { algorithm-id: algorithm-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= score u100) ERR_INVALID_INPUT)
    (map-set algorithms
      { algorithm-id: algorithm-id }
      (merge algorithm { transparency-score: score })
    )
    (ok true)
  )
)

;; Get algorithm details
(define-read-only (get-algorithm (algorithm-id uint))
  (map-get? algorithms { algorithm-id: algorithm-id })
)

;; Get decision log
(define-read-only (get-decision (algorithm-id uint) (decision-id uint))
  (map-get? decision-logs { algorithm-id: algorithm-id, decision-id: decision-id })
)
