;; Harmony Protocol - Decentralized Music Royalty System
;; A creative approach to music rights management on the blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-invalid-percentage (err u104))
(define-constant err-max-collaborators (err u105))
(define-constant err-song-locked (err u106))
(define-constant err-invalid-amount (err u107))
(define-constant err-stream-threshold-not-met (err u108))

;; Data Variables
(define-data-var song-counter uint u0)
(define-data-var total-platform-fees uint u0)
(define-data-var platform-fee-percentage uint u250) ;; 2.5% = 250 basis points

;; Data Maps
(define-map songs
    uint 
    {
        title: (string-ascii 64),
        artist: principal,
        total-shares: uint,
        available-shares: uint,
        share-price: uint,
        streaming-revenue: uint,
        locked: bool,
        creation-block: uint
    }
)

(define-map song-collaborators
    {song-id: uint, collaborator: principal}
    {percentage: uint}
)

(define-map shareholder-balances
    {song-id: uint, holder: principal}
    uint
)

(define-map listener-rewards
    {listener: principal, song-id: uint}
    {streams: uint, last-stream-block: uint}
)

(define-map artist-stats
    principal
    {total-songs: uint, total-revenue: uint, verified: bool}
)

;; Public Functions

;; Create a new song with tokenized shares
(define-public (create-song (title (string-ascii 64)) (total-shares uint) (share-price uint))
    (let
        (
            (song-id (+ (var-get song-counter) u1))
            (artist-stat (default-to 
                {total-songs: u0, total-revenue: u0, verified: false} 
                (map-get? artist-stats tx-sender)))
        )
        (asserts! (> total-shares u0) err-invalid-amount)
        (asserts! (> share-price u0) err-invalid-amount)
        
        (map-set songs song-id {
            title: title,
            artist: tx-sender,
            total-shares: total-shares,
            available-shares: total-shares,
            share-price: share-price,
            streaming-revenue: u0,
            locked: false,
            creation-block: block-height
        })
        
        (map-set artist-stats tx-sender 
            (merge artist-stat {total-songs: (+ (get total-songs artist-stat) u1)}))
        
        (var-set song-counter song-id)
        (ok song-id)
    )
)

;; Add collaborators to a song (up to 5)
(define-public (add-collaborator (song-id uint) (collaborator principal) (percentage uint))
    (let
        (
            (song (unwrap! (map-get? songs song-id) err-not-found))
            (total-collabs (fold check-collaborators 
                (list u1 u2 u3 u4 u5) 
                {song-id: song-id, count: u0}))
        )
        (asserts! (is-eq (get artist song) tx-sender) err-owner-only)
        (asserts! (not (get locked song)) err-song-locked)
        (asserts! (<= percentage u5000) err-invalid-percentage) ;; Max 50%
        (asserts! (< (get count total-collabs) u5) err-max-collaborators)
        
        (map-set song-collaborators 
            {song-id: song-id, collaborator: collaborator}
            {percentage: percentage})
        (ok true)
    )
)

;; Buy shares in a song
(define-public (buy-shares (song-id uint) (amount uint))
    (let
        (
            (song (unwrap! (map-get? songs song-id) err-not-found))
            (total-cost (* amount (get share-price song)))
            (platform-fee (/ (* total-cost (var-get platform-fee-percentage)) u10000))
            (artist-payment (- total-cost platform-fee))
            (current-balance (default-to u0 
                (map-get? shareholder-balances {song-id: song-id, holder: tx-sender})))
        )
        (asserts! (>= (get available-shares song) amount) err-insufficient-balance)
        (asserts! (> amount u0) err-invalid-amount)
        
        ;; Transfer payment
        (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
        
        ;; Pay artist
        (try! (as-contract (stx-transfer? artist-payment tx-sender (get artist song))))
        
        ;; Update platform fees
        (var-set total-platform-fees (+ (var-get total-platform-fees) platform-fee))
        
        ;; Update shares
        (map-set songs song-id 
            (merge song {available-shares: (- (get available-shares song) amount)}))
        
        ;; Update shareholder balance
        (map-set shareholder-balances 
            {song-id: song-id, holder: tx-sender}
            (+ current-balance amount))
        
        (ok true)
    )
)

;; Simulate streaming and distribute royalties
(define-public (stream-song (song-id uint) (revenue-amount uint))
    (let
        (
            (song (unwrap! (map-get? songs song-id) err-not-found))
            (listener-data (default-to 
                {streams: u0, last-stream-block: u0}
                (map-get? listener-rewards {listener: tx-sender, song-id: song-id})))
        )
        ;; In real implementation, this would be called by an oracle or streaming service
        (asserts! (> revenue-amount u0) err-invalid-amount)
        
        ;; Transfer streaming revenue to contract
        (try! (stx-transfer? revenue-amount tx-sender (as-contract tx-sender)))
        
        ;; Update song streaming revenue
        (map-set songs song-id 
            (merge song {streaming-revenue: (+ (get streaming-revenue song) revenue-amount)}))
        
        ;; Update listener rewards
        (map-set listener-rewards 
            {listener: tx-sender, song-id: song-id}
            {
                streams: (+ (get streams listener-data) u1),
                last-stream-block: block-height
            })
        
        ;; Distribute royalties if threshold met
        (if (>= (get streaming-revenue song) u1000000) ;; 1 STX minimum
            (distribute-royalties song-id)
            (ok true))
    )
)

;; Claim shareholder royalties
(define-public (claim-royalties (song-id uint))
    (let
        (
            (song (unwrap! (map-get? songs song-id) err-not-found))
            (shares (unwrap! 
                (map-get? shareholder-balances {song-id: song-id, holder: tx-sender}) 
                err-not-found))
            (total-revenue (get streaming-revenue song))
            (share-percentage (/ (* shares u10000) (get total-shares song)))
            (royalty-amount (/ (* total-revenue share-percentage) u10000))
        )
        (asserts! (> royalty-amount u0) err-invalid-amount)
        (asserts! (> shares u0) err-insufficient-balance)
        
        ;; Transfer royalties
        (try! (as-contract (stx-transfer? royalty-amount tx-sender tx-sender)))
        
        ;; Reset the proportional amount of streaming revenue
        (let ((remaining-revenue (- total-revenue royalty-amount)))
            (map-set songs song-id 
                (merge song {streaming-revenue: remaining-revenue})))
        
        (ok royalty-amount)
    )
)

;; Lock song to prevent further modifications
(define-public (lock-song (song-id uint))
    (let
        ((song (unwrap! (map-get? songs song-id) err-not-found)))
        (asserts! (is-eq (get artist song) tx-sender) err-owner-only)
        (map-set songs song-id (merge song {locked: true}))
        (ok true)
    )
)

;; Read-only functions

(define-read-only (get-song-info (song-id uint))
    (map-get? songs song-id)
)

(define-read-only (get-shareholder-balance (song-id uint) (holder principal))
    (default-to u0 (map-get? shareholder-balances {song-id: song-id, holder: holder}))
)

(define-read-only (get-artist-stats (artist principal))
    (map-get? artist-stats artist)
)

(define-read-only (get-listener-rewards (listener principal) (song-id uint))
    (map-get? listener-rewards {listener: listener, song-id: song-id})
)

(define-read-only (get-platform-fees)
    (var-get total-platform-fees)
)

;; Private functions

(define-private (distribute-royalties (song-id uint))
    (let
        ((song (unwrap! (map-get? songs song-id) err-not-found)))
        ;; In a full implementation, this would iterate through all shareholders
        ;; and distribute proportionally
        (ok true)
    )
)

(define-private (check-collaborators (idx uint) (acc {song-id: uint, count: uint}))
    (match (map-get? song-collaborators {song-id: (get song-id acc), collaborator: contract-owner})
        collab {song-id: (get song-id acc), count: (+ (get count acc) u1)}
        acc
    )
)

;; Admin functions

(define-public (update-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u1000) err-invalid-percentage) ;; Max 10%
        (var-set platform-fee-percentage new-fee)
        (ok true)
    )
)

(define-public (withdraw-platform-fees (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= amount (var-get total-platform-fees)) err-insufficient-balance)
        (try! (as-contract (stx-transfer? amount tx-sender contract-owner)))
        (var-set total-platform-fees (- (var-get total-platform-fees) amount))
        (ok true)
    )
)