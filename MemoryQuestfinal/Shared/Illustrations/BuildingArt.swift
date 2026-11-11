import SwiftUI
import UIKit

struct BuildingArt: View {
    let id: Int
    var empty = false
    @Environment(\.colorScheme) private var colorScheme

    static let assets = ["building-mid-1", "shop-2", "building-mid-2", "buiding-tall-2", "building-mid-1", "shop-2", "house small-2", "building-tall-1", "building-mid-1", "building-mid-2"]
    static let darkAssets = [
        "building-mid-1": "building-mid-1 1",
        "building-mid-2": "building-mid-2 1",
        "house small-2": "house small-2 1",
        "shop-2": "shop-2 1"
    ]

    static func asset(for id: Int, colorScheme: ColorScheme) -> String {
        let asset = assets[id]
        return colorScheme == .dark ? darkAssets[asset, default: asset] : asset
    }

    // Match the actual asset palette, including buildings reused by different lessons.
    static func accent(for id: Int) -> Color {
        switch assets[id] {
        case "shop-2": Color(hex: "9B47B0")
        case "building-mid-2": Color(hex: "196780")
        case "buiding-tall-2": Color(hex: "435E9D")
        case "building-tall-1": Color(hex: "68A961")
        case "house small-2": Color(hex: "BEA418")
        default: Color(hex: "B43E3E")
        }
    }

    var body: some View {
        if empty {
            Image(systemName: "lock.fill").foregroundStyle(AppTheme.muted).accessibilityHidden(true)
        } else {
            Image(Self.asset(for: id, colorScheme: colorScheme)).resizable().scaledToFit().accessibilityHidden(true)
        }
    }
}

// The expanded canvas scrolls vertically and horizontally even at the default zoom.
struct CityIllustration: View {
    let buildings: Set<Int>
    var fadesTop = true
    var aspectRatio: CGFloat = 405.0 / 370.0
    var initialVerticalOffset: CGFloat = 0
    var newBuildingID: Int? = nil
    var select: (Int) -> Void = { _ in }
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            BoundedMapScrollView(
                unlockedPlotIDs: buildings,
                initialVerticalOffset: initialVerticalOffset,
                newBuildingID: newBuildingID,
                select: select
            )
            .accessibilityLabel("City map")
            .accessibilityHint("Drag to explore. Pinch to zoom in or out.")
            CityNightOverlay()
                .opacity(colorScheme == .dark ? 1 : 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .background(AppTheme.background)
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipped()
        // Keep the feathered edges fixed to the viewport as the map moves.
        .mask {
            LinearGradient(
                stops: [
                    .init(color: fadesTop ? .clear : .black, location: 0),
                    .init(color: .black.opacity(fadesTop ? 0.25 : 1), location: 0.04),
                    .init(color: .black, location: 0.16),
                    .init(color: .black, location: 0.82),
                    .init(color: .black.opacity(0.25), location: 0.96),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .animation(.easeInOut(duration: 0.35), value: colorScheme)
    }
}

private struct CityNightOverlay: View {
    var body: some View {
        Color.black
            .opacity(0.08)
            .blendMode(.multiply)
    }
}

// UIKit owns both gestures so dragging and pinching share one coordinate space.
private struct BoundedMapScrollView: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    let unlockedPlotIDs: Set<Int>
    var initialVerticalOffset: CGFloat = 0
    var newBuildingID: Int? = nil
    let select: (Int) -> Void

    func makeUIView(context: Context) -> MapScrollView {
        MapScrollView(initialVerticalOffset: initialVerticalOffset, newBuildingID: newBuildingID)
    }

    func updateUIView(_ scrollView: MapScrollView, context: Context) {
        scrollView.updatePlots(unlockedIDs: unlockedPlotIDs, select: select)
        scrollView.updateAppearance(colorScheme)
    }
}

private final class MapScrollView: UIScrollView, UIScrollViewDelegate {
    private let canvas = UIView(frame: CGRect(origin: .zero, size: CityRoadLayout.canvasSize))
    private let mapImageView = CityRoadCanvasView()
    private let streetlampView = CityStreetlampCanvasView()
    private let carViews = CityCarView.makeCityCars()
    private let treeView = CityTreeCanvasView()
    private var previousViewport = CGSize.zero
    private let initialVerticalOffset: CGFloat
    private let newBuildingID: Int?
    private let plotViews = CityPlot.reserved.sorted { $0.groundCenter.y < $1.groundCenter.y }
        .map { CityPlotView(plot: $0) }

    init(initialVerticalOffset: CGFloat, newBuildingID: Int?) {
        self.initialVerticalOffset = initialVerticalOffset
        self.newBuildingID = newBuildingID
        super.init(frame: .zero)
        delegate = self
        bounces = false
        bouncesZoom = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        isDirectionalLockEnabled = false
        canCancelContentTouches = true
        addSubview(canvas)
        mapImageView.frame = canvas.bounds
        canvas.addSubview(mapImageView)
        for facility in CityFacility.placements {
            canvas.addSubview(facility.makeImageView())
        }
        streetlampView.frame = canvas.bounds
        canvas.addSubview(streetlampView)
        for carView in carViews {
            canvas.addSubview(carView)
        }
        treeView.frame = canvas.bounds
        canvas.addSubview(treeView)
        for plotView in plotViews {
            canvas.addSubview(plotView)
            if plotView.plot.id == newBuildingID {
                plotView.prepareConstruction()
            }
        }
        contentSize = canvas.bounds.size
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(toggleZoom(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Zoom in", target: self, selector: #selector(zoomIn)),
            UIAccessibilityCustomAction(name: "Zoom out", target: self, selector: #selector(zoomOut))
        ]
    }

    required init?(coder: NSCoder) { nil }

    func updatePlots(unlockedIDs: Set<Int>, select: @escaping (Int) -> Void) {
        for plotView in plotViews {
            plotView.isUnlocked = unlockedIDs.contains(plotView.plot.id)
            let id = plotView.plot.id
            plotView.onSelect = { select(id) }
        }
    }

    func updateAppearance(_ colorScheme: ColorScheme) {
        let isNight = colorScheme == .dark
        canvas.backgroundColor = isNight
            ? UIColor(white: 0.105, alpha: 1)
            : .clear
        streetlampView.isLit = isNight
        for plotView in plotViews {
            plotView.updateAppearance(colorScheme)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { canvas }

    override func touchesShouldCancel(in view: UIView) -> Bool {
        // A drag starting over a building must pan instead of holding its button.
        true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0, bounds.size != previousViewport else { return }
        let firstLayout = previousViewport == .zero
        let oldMinimum = minimumZoomScale
        let center = CGPoint(x: (contentOffset.x + previousViewport.width / 2) / zoomScale,
                             y: (contentOffset.y + previousViewport.height / 2) / zoomScale)
        let relativeZoom = zoomScale / max(oldMinimum, 0.001)
        previousViewport = bounds.size
        // At the minimum scale the canvas fills the viewport, with no blank margins.
        minimumZoomScale = max(bounds.width / canvas.bounds.width, bounds.height / canvas.bounds.height)
        maximumZoomScale = minimumZoomScale * 4
        setZoomScale(min(maximumZoomScale, minimumZoomScale * (firstLayout ? 1.5 : relativeZoom)), animated: false)
        // Shift the initial framing without leaving an empty strip above the map.
        let newPlot = plotViews.first { $0.plot.id == newBuildingID }
        let initialCenter = newPlot.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) }
            ?? CGPoint(x: canvas.bounds.midX, y: canvas.bounds.midY - initialVerticalOffset / zoomScale)
        let target = firstLayout ? initialCenter : center
        contentOffset = CGPoint(
            x: min(max(0, target.x * zoomScale - bounds.width / 2), max(0, contentSize.width - bounds.width)),
            y: min(max(0, target.y * zoomScale - bounds.height / 2), max(0, contentSize.height - bounds.height))
        )
    }

    @objc private func toggleZoom(_ gesture: UITapGestureRecognizer) {
        let scale = zoomScale > minimumZoomScale * 2 ? minimumZoomScale : min(zoomScale * 2, maximumZoomScale)
        let point = gesture.location(in: canvas)
        zoom(to: CGRect(x: point.x - bounds.width / scale / 2,
                        y: point.y - bounds.height / scale / 2,
                        width: bounds.width / scale, height: bounds.height / scale), animated: !UIAccessibility.isReduceMotionEnabled)
    }

    @objc private func zoomIn() -> Bool {
        setZoomScale(min(zoomScale * 1.5, maximumZoomScale), animated: !UIAccessibility.isReduceMotionEnabled)
        return true
    }

    @objc private func zoomOut() -> Bool {
        setZoomScale(max(zoomScale / 1.5, minimumZoomScale), animated: !UIAccessibility.isReduceMotionEnabled)
        return true
    }
}

private struct CityFacility {
    let asset: String
    let groundCenter: CGPoint
    let width: CGFloat
    let groundY: CGFloat

    // Use a few unreserved plots and leave open space between them.
    static let placements = [
        CityFacility(asset: "Playground", groundCenter: CityRoadLayout.plotCenter(column: -2, row: 0), width: 254, groundY: 40),
        CityFacility(asset: "Park", groundCenter: CityRoadLayout.plotCenter(column: 0, row: -2), width: 272, groundY: 40),
        // Set the fountain to the right of the grove in the same block.
        CityFacility(asset: "Fountain", groundCenter: CityRoadLayout.plotCenter(column: -0.83, row: 0.82), width: 174, groundY: 41),
        CityFacility(asset: "Sports Field", groundCenter: CityRoadLayout.plotCenter(column: 0.97, row: 1.97), width: 298, groundY: 30)
    ]

    func makeImageView() -> UIImageView {
        let view = UIImageView(image: UIImage(named: asset))
        // The SVGs share an 86 × 68 view box with different ground centers.
        let scale = width / 86
        view.frame = CGRect(
            x: groundCenter.x - width / 2,
            y: groundCenter.y - groundY * scale,
            width: width,
            height: 68 * scale
        )
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true
        return view
    }
}

// Coordinates use the map's original 1600 × 1920 canvas, independent of screen size.
private struct CityPlot: Identifiable {
    let id: Int
    let assetSize: CGSize
    let groundCenter: CGPoint

    private var buildingSize: CGSize {
        CGSize(width: assetSize.width * 1.5, height: assetSize.height * 1.5)
    }

    var footprintSize: CGSize {
        let width = buildingSize.width + 28
        return CGSize(width: width, height: width * 4 / 7)
    }

    var reservedFrame: CGRect {
        let size = buildingSize
        // The isometric base's front corner is below its ground center.
        let bottom = groundCenter.y + size.width * 2 / 7
        return CGRect(
            x: groundCenter.x - footprintSize.width / 2,
            y: bottom - size.height,
            width: footprintSize.width,
            height: size.height + 8
        )
    }

    var buildingFrame: CGRect {
        CGRect(x: 14, y: 0, width: buildingSize.width, height: buildingSize.height)
    }

    // Stable IDs are the integration point for future saved unlock progress.
    static let reserved: [CityPlot] = [
        CityPlot(id: 6, assetSize: CGSize(width: 105, height: 107), groundCenter: CityRoadLayout.plotCenter(column: -1, row: 0)),
        CityPlot(id: 0, assetSize: CGSize(width: 135, height: 174), groundCenter: CityRoadLayout.plotCenter(column: 0, row: 0)),
        CityPlot(id: 2, assetSize: CGSize(width: 119, height: 164), groundCenter: CityRoadLayout.plotCenter(column: 0, row: -1)),
        CityPlot(id: 1, assetSize: CGSize(width: 144, height: 145), groundCenter: CityRoadLayout.plotCenter(column: 0, row: 1)),
        CityPlot(id: 3, assetSize: CGSize(width: 135, height: 300), groundCenter: CityRoadLayout.plotCenter(column: 1, row: 0)),
        CityPlot(id: 7, assetSize: CGSize(width: 131, height: 298), groundCenter: CityRoadLayout.plotCenter(column: 1, row: 1)),
        CityPlot(id: 4, assetSize: CGSize(width: 135, height: 174), groundCenter: CityRoadLayout.plotCenter(column: -1, row: -1)),
        CityPlot(id: 5, assetSize: CGSize(width: 144, height: 145), groundCenter: CityRoadLayout.plotCenter(column: -1, row: 2)),
        CityPlot(id: 8, assetSize: CGSize(width: 135, height: 174), groundCenter: CityRoadLayout.plotCenter(column: 2, row: -1)),
        CityPlot(id: 9, assetSize: CGSize(width: 119, height: 164), groundCenter: CityRoadLayout.plotCenter(column: 2, row: 1))
    ]
}

private final class CityPlotView: UIControl {
    var onSelect: (() -> Void)?

    override func accessibilityActivate() -> Bool {
        onSelect?()
        return true
    }

    @objc private func openPlot() { onSelect?() }
    let plot: CityPlot
    private let buildingImageView: UIImageView
    private let groundShadowView = UIView()
    private var hitMask: BuildingHitMask?
    private var isDarkAppearance = false

    func updateAppearance(_ colorScheme: ColorScheme) {
        let isDark = colorScheme == .dark
        guard isDarkAppearance != isDark else { return }
        isDarkAppearance = isDark
        let asset = BuildingArt.asset(for: plot.id, colorScheme: colorScheme)
        let image = UIImage(named: asset)
        buildingImageView.image = image
        hitMask = BuildingHitMask(image: image)
        groundShadowView.layer.shadowOpacity = isDark ? 0.58 : 0.22
        setNeedsDisplay()
    }

    private let constructionTrack = UIView()
    private let constructionFill = UIView()
    private var constructionPending = false
    private var constructionStarted = false
    private var constructionTask: Task<Void, Never>?

    func prepareConstruction() {
        constructionPending = true
        buildingImageView.alpha = 0
        groundShadowView.alpha = 0
        isUserInteractionEnabled = false
        constructionTrack.backgroundColor = .systemGray4
        constructionTrack.layer.cornerRadius = 7
        constructionTrack.layer.zPosition = 1_000
        constructionTrack.clipsToBounds = true
        constructionTrack.frame = CGRect(
            x: plot.groundCenter.x - 70,
            y: plot.groundCenter.y - 7,
            width: 140, height: 14
        )
        constructionFill.backgroundColor = UIColor(AppTheme.coral)
        constructionFill.frame = CGRect(x: 0, y: 0, width: 0, height: 14)
        constructionTrack.addSubview(constructionFill)
        // Center the small bar in the destination plot, above neighboring map artwork.
        superview?.addSubview(constructionTrack)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else {
            if constructionStarted {
                constructionTask?.cancel()
                constructionTask = nil
                constructionFill.layer.removeAllAnimations()
                buildingImageView.layer.removeAllAnimations()
                groundShadowView.layer.removeAllAnimations()
                finishConstruction(animated: false)
            }
            return
        }
        guard constructionPending, !constructionStarted else { return }
        constructionStarted = true
        accessibilityValue = String(localized: "Building in progress")
        // Begin outside SwiftUI's initial layout transaction, after navigation settles.
        // Explicit timed updates also keep the bar visible when UIKit animations are disabled.
        constructionTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(350))
                for step in 1...60 {
                    try await Task.sleep(for: .milliseconds(50))
                    guard let self, self.window != nil else { return }
                    self.constructionFill.frame.size.width =
                        self.constructionTrack.bounds.width * CGFloat(step) / 60
                    self.accessibilityValue = String(localized: "Building in progress") + " \(step * 100 / 60)%"
                }
                self?.finishConstruction(animated: true)
            } catch {
                // Leaving the city cancels the presentation; the reward is already saved.
            }
        }
    }

    private func finishConstruction(animated: Bool) {
        constructionPending = false
        constructionTrack.removeFromSuperview()
        accessibilityValue = nil
        isUserInteractionEnabled = true
        UIView.animate(
            withDuration: animated && !UIAccessibility.isReduceMotionEnabled ? 0.8 : 0,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            self.buildingImageView.alpha = 1
            self.groundShadowView.alpha = 1
        }
    }
    var isUnlocked = false {
        didSet {
            guard oldValue != isUnlocked else { return }
            buildingImageView.isHidden = !isUnlocked
            groundShadowView.isHidden = !isUnlocked
            accessibilityLabel = isUnlocked
                ? "Open \(ContentRepository.challenges[plot.id].building)"
                : "Preview locked \(ContentRepository.challenges[plot.id].building)"
            setNeedsDisplay()
        }
    }

    init(plot: CityPlot) {
        self.plot = plot
        let image = UIImage(named: BuildingArt.asset(for: plot.id, colorScheme: .light))
        buildingImageView = UIImageView(image: image)
        hitMask = BuildingHitMask(image: image)
        super.init(frame: plot.reservedFrame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = true
        addTarget(self, action: #selector(openPlot), for: .touchUpInside)
        isAccessibilityElement = true
        accessibilityLabel = "Preview locked \(ContentRepository.challenges[plot.id].building)"
        accessibilityTraits = .button

        groundShadowView.frame = bounds
        groundShadowView.isHidden = true
        groundShadowView.isUserInteractionEnabled = false
        groundShadowView.layer.shadowPath = footprintPath.cgPath
        groundShadowView.layer.shadowColor = UIColor.black.cgColor
        groundShadowView.layer.shadowOpacity = 0.22
        groundShadowView.layer.shadowOffset = CGSize(width: 5, height: 6)
        groundShadowView.layer.shadowRadius = 12
        addSubview(groundShadowView)

        buildingImageView.frame = plot.buildingFrame
        buildingImageView.contentMode = .scaleAspectFit
        buildingImageView.isHidden = true
        addSubview(buildingImageView)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private lazy var footprintPath: UIBezierPath = {
        let footprint = plot.footprintSize
        let center = CGPoint(
            x: bounds.midX,
            y: plot.groundCenter.y - plot.reservedFrame.minY
        )
        let path = UIBezierPath()
        path.move(to: CGPoint(x: center.x, y: center.y - footprint.height / 2))
        path.addLine(to: CGPoint(x: center.x + footprint.width / 2, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + footprint.height / 2))
        path.addLine(to: CGPoint(x: center.x - footprint.width / 2, y: center.y))
        path.close()
        return path
    }()

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isUnlocked else { return footprintPath.contains(point) }
        guard let image = buildingImageView.image else { return false }
        let frame = buildingImageView.frame
        let scale = min(frame.width / image.size.width, frame.height / image.size.height)
        let width = image.size.width * scale
        let height = image.size.height * scale
        let imageRect = CGRect(x: frame.midX - width / 2, y: frame.midY - height / 2, width: width, height: height)
        guard imageRect.contains(point) else { return false }
        // Transparent parts of foreground buildings let taps reach the artwork behind them.
        return hitMask?.contains(
            x: (point.x - imageRect.minX) / width,
            y: (point.y - imageRect.minY) / height
        ) ?? true
    }

    override func draw(_ rect: CGRect) {
        guard !isUnlocked else { return }
        let lockedColor = isDarkAppearance
            ? UIColor.white.withAlphaComponent(0.82)
            : UIColor.darkGray.withAlphaComponent(0.65)
        lockedColor.setStroke()
        footprintPath.lineWidth = 2.5
        footprintPath.setLineDash([8, 6], count: 2, phase: 0)
        footprintPath.stroke()

        let center = CGPoint(x: bounds.midX, y: plot.groundCenter.y - plot.reservedFrame.minY)
        let lock = UIImage(systemName: "lock.fill")?.withTintColor(
            lockedColor,
            renderingMode: .alwaysOriginal
        )
        lock?.draw(in: CGRect(x: center.x - 11, y: center.y - 14, width: 22, height: 28))
    }
}

private struct BuildingHitMask {
    private let width: Int
    private let height: Int
    private let alpha: [UInt8]

    init?(image: UIImage?) {
        guard let image, let source = image.cgImage else { return nil }
        let width = Int(image.size.width.rounded(.up))
        let height = Int(image.size.height.rounded(.up))
        guard width > 0, height > 0 else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drewImage = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                                            | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drewImage else { return nil }
        self.width = width
        self.height = height
        alpha = stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] }
    }

    func contains(x: CGFloat, y: CGFloat) -> Bool {
        let column = min(Int(x * CGFloat(width)), width - 1)
        let row = min(Int(y * CGFloat(height)), height - 1)
        return alpha[row * width + column] > 32
    }
}


/// Small vehicles share the map coordinate space, so they stay attached to roads while zooming and panning.
private final class CityCarView: UIView {
    private let startPoint: CGPoint
    private let endPoint: CGPoint
    private let travelDuration: TimeInterval
    private let startDelay: TimeInterval

    init(start: CGPoint, end: CGPoint, color: UIColor, duration: TimeInterval, delay: TimeInterval) {
        startPoint = start
        endPoint = end
        travelDuration = duration
        startDelay = delay
        super.init(frame: CGRect(x: 0, y: 0, width: 28, height: 14))

        center = start
        backgroundColor = color
        layer.cornerRadius = 5
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true

        let angle = atan2(end.y - start.y, end.x - start.x)
        transform = CGAffineTransform(rotationAngle: angle)

        let windshield = UIView(frame: CGRect(x: 9, y: 3, width: 10, height: 8))
        windshield.backgroundColor = UIColor.darkGray.withAlphaComponent(0.65)
        windshield.layer.cornerRadius = 2
        addSubview(windshield)
    }

    required init?(coder: NSCoder) { nil }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        layer.removeAnimation(forKey: "cityDrive")
        guard window != nil, !UIAccessibility.isReduceMotionEnabled else {
            center = startPoint
            return
        }

        let drive = CABasicAnimation(keyPath: "position")
        drive.fromValue = startPoint
        drive.toValue = endPoint
        drive.duration = travelDuration
        drive.beginTime = CACurrentMediaTime() + startDelay
        drive.repeatCount = .infinity
        drive.autoreverses = true
        drive.timingFunction = CAMediaTimingFunction(name: .linear)
        drive.isRemovedOnCompletion = false
        layer.add(drive, forKey: "cityDrive")
    }

    static func makeCityCars() -> [CityCarView] {
        let white = UIColor(white: 0.96, alpha: 1)
        return [
            CityCarView(
                start: CityRoadLayout.point(column: -4.67, row: -1),
                end: CityRoadLayout.point(column: 2.67, row: -1),
                color: white,
                duration: 18,
                delay: 0
            ),
            CityCarView(
                start: CityRoadLayout.point(column: -1.67, row: 2),
                end: CityRoadLayout.point(column: 5.67, row: 2),
                color: white,
                duration: 18,
                delay: 2
            ),
            CityCarView(
                start: CityRoadLayout.point(column: -3.75, row: -3),
                end: CityRoadLayout.point(column: 0.67, row: -3),
                color: white,
                duration: 14,
                delay: 4
            ),
            CityCarView(
                start: CityRoadLayout.point(column: 3, row: -0.67),
                end: CityRoadLayout.point(column: 3, row: 5.75),
                color: white,
                duration: 17,
                delay: 1
            ),
            CityCarView(
                start: CityRoadLayout.point(column: -3, row: -3.75),
                end: CityRoadLayout.point(column: -3, row: 0.67),
                color: white,
                duration: 14,
                delay: 6
            )
        ]
    }
}

/// Shared coordinates keep roads, planting and building plots aligned.
enum CityRoadLayout {
    static let canvasSize = CGSize(width: 1600, height: 1920)

    static func point(column: CGFloat, row: CGFloat) -> CGPoint {
        CGPoint(x: 800 + (column - row) * 210, y: 840 + (column + row) * 120)
    }

    static func plotCenter(column: CGFloat, row: CGFloat) -> CGPoint {
        point(column: column + 0.5, row: row + 0.5)
    }
}

final class CityRoadCanvasView: UIView {
    private let horizontal = UIImage(named: "road-horizontal")
    private let vertical = UIImage(named: "road-vertical")
    private let junction = UIImage(named: "road-junction")
    private let missingNorthwest = UIImage(named: "road-t junction-1")
    private let missingSoutheast = UIImage(named: "road-t junction-2")
    private let missingNortheast = UIImage(named: "road-t junction-3")
    private let missingSouthwest = UIImage(named: "road-t junction-4")

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { nil }

    // Omitted links merge selected blocks into longer, staggered green spaces.
    private func omitsVertical(_ column: Int, _ row: Int) -> Bool {
        (column == -1 && row == 0) || (column == 2 && row == 1)
            || (column == -3 && row == -2) || (column == 0 && row == 1)
            || (column == -2 && row == 1) || (column == 0 && row == -2)
            || (column == 3 && row == 3) || (column == -3 && row == -4)
    }

    private func omitsHorizontal(_ column: Int, _ row: Int) -> Bool {
        (column == 1 && row == -1) || (column == -1 && row == 2)
            || (column == 2 && row == 3) || (column == 2 && row == -2)
            || (column == -2 && row == -1) || (column == 4 && row == 0)
            || (column == 0 && row == 3) || (column == -4 && row == -2)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.scaleBy(
            x: bounds.width / CityRoadLayout.canvasSize.width,
            y: bounds.height / CityRoadLayout.canvasSize.height
        )
        for column in -7...7 {
            for row in -7...7 {
                let center = CityRoadLayout.point(column: CGFloat(column), row: CGFloat(row))
                let intersection: UIImage?
                if omitsVertical(column, row) {
                    intersection = missingSoutheast
                } else if omitsVertical(column - 1, row) {
                    intersection = missingNorthwest
                } else if omitsHorizontal(column, row) {
                    intersection = missingSouthwest
                } else if omitsHorizontal(column, row - 1) {
                    intersection = missingNortheast
                } else {
                    intersection = junction
                }
                let intersectionFrame = CGRect(x: center.x - 84, y: center.y - 48, width: 168, height: 96)
                intersection?.draw(in: intersectionFrame)

                let verticalFrame = CGRect(x: center.x + 42, y: center.y + 24, width: 126, height: 72)
                if !omitsVertical(column, row) {
                    vertical?.draw(in: verticalFrame)
                }

                let horizontalFrame = CGRect(x: center.x - 168, y: center.y + 24, width: 126, height: 72)
                if !omitsHorizontal(column, row) {
                    horizontal?.draw(in: horizontalFrame)
                }
            }
        }

        context.restoreGState()
    }
}

private final class CityStreetlampCanvasView: UIView {
    private let lamp = UIImage(named: "Streetlamp")
    private let glow = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            UIColor(red: 1, green: 0.89, blue: 0.55, alpha: 0.88).cgColor,
            UIColor(red: 1, green: 0.67, blue: 0.24, alpha: 0).cgColor
        ] as CFArray,
        locations: [0, 1]
    )
    // Mid-block curb positions on road segments that are present in the layout.
    private let curbs: [(column: CGFloat, row: CGFloat)] = [
        (-2.5, -2.9), (-1.9, -1.5), (-1.5, -0.1), (-0.1, -2.5),
        (-0.5, -0.9), (0.9, -1.5), (0.5, -0.1), (1.5, 0.1),
        (-1.5, 1.9), (-0.5, 1.1), (0.1, 2.5), (1.5, 2.1),
        (2.9, 0.5), (2.5, 2.1), (3.5, 1.9), (3.1, 4.5)
    ]

    var isLit = false {
        didSet {
            if oldValue != isLit { setNeedsDisplay() }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }

    required init?(coder: NSCoder) { nil }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let scale: CGFloat = 1.8
        for curb in curbs {
            let foot = CityRoadLayout.point(column: curb.column, row: curb.row)
            let frame = CGRect(x: foot.x - 10 * scale, y: foot.y - 36 * scale,
                               width: 24 * scale, height: 40 * scale)
            lamp?.draw(in: frame)
            if isLit, let glow {
                let bulb = CGPoint(x: frame.minX + 18 * scale, y: frame.minY + 12 * scale)
                context.drawRadialGradient(glow, startCenter: bulb, startRadius: 2 * scale,
                                           endCenter: bulb, endRadius: 19 * scale, options: [.drawsBeforeStartLocation])
            }
        }
    }
}

/// Tree clusters render above traffic, so cars pass behind roadside foliage.
private final class CityTreeCanvasView: UIView {
    private let tree = UIImage(named: "tree")

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { nil }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.scaleBy(
            x: bounds.width / CityRoadLayout.canvasSize.width,
            y: bounds.height / CityRoadLayout.canvasSize.height
        )

        // Fixed, asymmetric placements stay stable during redraws and zooming.
        let groves: [(column: CGFloat, row: CGFloat, width: CGFloat)] = [
            (-2.12, -0.91, 108), (-0.86, -2.08, 132),
            (1.12, -0.88, 102), (-1.15, 1.08, 125),
            (2.08, 0.16, 138), (0.12, 2.28, 94),
            (-2.06, 1.13, 112), (1.16, -2.11, 92),
            (2.13, 2.06, 122), (3.04, 0.85, 98),
            (-3.12, -1.88, 134), (-1.87, -3.14, 100),
            (3.16, 3.03, 110), (1.9, 4.12, 130)
        ]
        for grove in groves.sorted(by: { $0.column + $0.row < $1.column + $1.row }) {
            let center = CityRoadLayout.plotCenter(column: grove.column, row: grove.row)
            let trunks: [(x: CGFloat, y: CGFloat, width: CGFloat)] = [
                (0.03, -0.20, 0.53),
                (0.27, 0.02, 0.36),
                (-0.24, 0.14, 0.44)
            ]
            for trunk in trunks {
                let scale = grove.width * trunk.width / 26
                let frame = CGRect(
                    x: center.x + grove.width * trunk.x - 14.5 * scale,
                    y: center.y + grove.width * trunk.y - 32 * scale,
                    width: 26 * scale,
                    height: 33 * scale
                )
                tree?.draw(in: frame)
            }
        }
        context.restoreGState()
    }
}

#Preview("Reference city · All buildings") {
    CityIllustration(buildings: Set(0..<10))
        .background(AppTheme.background)
}

#if DEBUG
#Preview("BuildingArt") {
    PreviewScreen() { BuildingArt(id: 1).frame(height: 180) }
}

#Preview("BoundedMapScrollView") {
    PreviewScreen() { BoundedMapScrollView(unlockedPlotIDs: [0, 1], select: { _ in }) }
}
#endif
