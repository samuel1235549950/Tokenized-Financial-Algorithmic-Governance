;; Bias Detection Contract
;; Identifies and tracks algorithmic bias in financial decisions

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_NOT_FOUND (err u301))
(define-constant ERR_INVALID_INPUT (err u302))

(define-data-var bias-report-counter uint u0)

;; Bias detection reports
(define-map bias-reports
  { report-id: uint }
  {
    algorithm-id: uint,
    bias-type: (string-ascii 50),
    severity: uint,
    affected-groups: (string-ascii 200),
    detection-method: (string-ascii 100),
    timestamp: uint,
    reporter: principal,
    status: (string-ascii 20)
  }
)

;; Bias metrics tracking
(define-map bias-metrics
  { algorithm-id: uint, metric-type: (string-ascii 50) }
  {
    value: uint,
    threshold: uint,
    last-updated: uint
  }
)

;; Authorized bias auditors
(define-map authorized-auditors principal bool)

;; Initialize contract owner as authorized auditor
(map-set authorized-auditors CONTRACT_OWNER true)

;; Add authorized auditor
(define-public (add-auditor (auditor principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set authorized-auditors auditor true))
  )
)

;; Report bias detection
(define-public (report-bias
  (algorithm-id uint)
  (bias-type (string-ascii 50))
  (severity uint)
  (affected-groups (string-ascii 200))
  (detection-method (string-ascii 100)))
  (let ((report-id (+ (var-get bias-report-counter) u1)))
    (asserts! (<= severity u10) ERR_INVALID_INPUT)
    (map-set bias-reports
      { report-id: report-id }
      {
        algorithm-id: algorithm-id,
        bias-type: bias-type,
        severity: severity,
        affected-groups: affected-groups,
        detection-method: detection-method,
        timestamp: block-height,
        reporter: tx-sender,
        status: "open"
      }
    )
    (var-set bias-report-counter report-id)
    (ok report-id)
  )
)

;; Update bias metric
(define-public (update-bias-metric
  (algorithm-id uint)
  (metric-type (string-ascii 50))
  (value uint)
  (threshold uint))
  (begin
    (asserts! (default-to false (map-get? authorized-auditors tx-sender)) ERR_UNAUTHORIZED)
    (map-set bias-metrics
      { algorithm-id: algorithm-id, metric-type: metric-type }
      {
        value: value,
        threshold: threshold,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

;; Resolve bias report
(define-public (resolve-bias-report (report-id uint) (resolution (string-ascii 20)))
  (let ((report (unwrap! (map-get? bias-reports { report-id: report-id }) ERR_NOT_FOUND)))
    (asserts! (default-to false (map-get? authorized-auditors tx-sender)) ERR_UNAUTHORIZED)
    (map-set bias-reports
      { report-id: report-id }
      (merge report { status: resolution })
    )
    (ok true)
  )
)

;; Get bias report
(define-read-only (get-bias-report (report-id uint))
  (map-get? bias-reports { report-id: report-id })
)

;; Get bias metric
(define-read-only (get-bias-metric (algorithm-id uint) (metric-type (string-ascii 50)))
  (map-get? bias-metrics { algorithm-id: algorithm-id, metric-type: metric-type })
)

;; Check if bias threshold exceeded
(define-read-only (is-bias-threshold-exceeded (algorithm-id uint) (metric-type (string-ascii 50)))
  (match (map-get? bias-metrics { algorithm-id: algorithm-id, metric-type: metric-type })
    metric (> (get value metric) (get threshold metric))
    false
  )
)
