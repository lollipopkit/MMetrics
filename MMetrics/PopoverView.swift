import SwiftUI
import ServiceManagement
import WidgetKit

enum AppTheme: String, CaseIterable, Identifiable {
    case automatic
    case light
    case dark

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Root

struct PopoverView: View {
    @ObservedObject var model: SystemStatsModel
    @State private var showSettings = false
    @AppStorage("appTheme") private var appTheme = AppTheme.automatic.rawValue

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                Header(model: model, showSettings: $showSettings)
                SectionIf(.cpu) { CPUSection(model: model) }
                SectionIf(.gpu) { GPUSection(model: model) }
                if model.fanRPM > 0 {
                    SectionIf(.fan) { FanSection(model: model) }
                }
                SectionIf(.memory) { MemorySection(model: model) }
                SectionIf(.battery) { BatterySection(model: model) }
                NetworkDiskSection(model: model)
                SectionIf(.power) { PowerSection(model: model) }
                SectionIf(.processes) { ProcessSection(model: model) }
            }
        }
        .frame(width: 340)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)
        .sheet(isPresented: $showSettings) {
            SettingsSheet(isPresented: $showSettings)
        }
    }

}

private struct SectionSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 14)
    }
}

/// Renders a separator plus `content` only while the section is enabled in Settings.
private struct SectionIf<Content: View>: View {
    @AppStorage private var enabled: Bool
    private let content: Content

    init(_ section: DashboardSection, @ViewBuilder content: () -> Content) {
        _enabled = AppStorage(wrappedValue: true, section.defaultsKey)
        self.content = content()
    }

    var body: some View {
        if enabled {
            SectionSeparator()
            content
        }
    }
}

// MARK: - Header

private struct Header: View {
    @ObservedObject var model: SystemStatsModel
    @Binding var showSettings: Bool
    @ObservedObject private var updater = UpdateChecker.shared

    var thermalColor: Color {
        switch model.thermalState {
        case "Normal":   return Color(hex: "30D158")
        case "Fair":     return Color(hex: "FFD60A")
        default:         return Color(hex: "FF453A")
        }
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.chipName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                HStack(spacing: 5) {
                    Circle().fill(thermalColor).frame(width: 6, height: 6)
                    Text(model.thermalState)
                        .font(.system(size: 11))
                        .foregroundColor(thermalColor)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f W", model.totalPower))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                Text("total power")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Button { showSettings = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "888899"))
                        .padding(.leading, 12)
                    if updater.updateAvailable {
                        Circle()
                            .fill(Color(hex: "FF9F0A"))
                            .frame(width: 7, height: 7)
                            .offset(x: -2, y: 1)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("Settings")
            Button { NSApp.terminate(nil) } label: {
                Image(systemName: "power")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "888899"))
                    .padding(.leading, 10)
            }
            .buttonStyle(.plain)
            .help("Quit MMetrics")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - CPU

private struct CPUSection: View {
    @ObservedObject var model: SystemStatsModel
    var body: some View {
        SectionBox(icon: "cpu", title: "CPU") {
            Row(label: "Overall") { StatBar(pct: model.cpuUsage) }
            ForEach(Array(model.cpuTiers.enumerated()), id: \.offset) { _, tier in
                let stats = model.clusterStats(tier.kind)
                Row(label: "\(tier.kind.label)-cluster  \(stats.mhz) MHz") {
                    StatBar(pct: stats.pct, color: tier.kind.color)
                }
            }
            if !model.perCoreCPU.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    ForEach(Array(model.perCoreCPU.enumerated()), id: \.offset) { i, pct in
                        CoreTile(index: i, pct: pct, tint: tierKind(forCore: i).color)
                    }
                }
                .padding(.top, 4)
            }
            HStack {
                Pill(icon: "thermometer", val: String(format: "%.0f°C", model.cpuTemp),
                     color: tempColor(model.cpuTemp))
                if model.cpuDieHotspot > 0 {
                    Pill(icon: "thermometer.sun.fill",
                         val: String(format: "%.0f°C", model.cpuDieHotspot),
                         color: tempColor(model.cpuDieHotspot))
                }
                Spacer()
                Pill(icon: "bolt", val: String(format: "%.2f W", model.cpuPower),
                     color: Color(hex: "FFD60A"))
            }
            .padding(.top, 2)
        }
    }

    private func tierKind(forCore index: Int) -> CPUTier.Kind {
        var upper = 0
        for tier in model.cpuTiers {
            upper += tier.cores
            if index < upper { return tier.kind }
        }
        return model.cpuTiers.last?.kind ?? .performance
    }
}

private extension CPUTier.Kind {
    var label: String {
        switch self {
        case .efficiency:  return "E"
        case .performance: return "P"
        case .super:       return "S"
        }
    }

    var color: Color {
        switch self {
        case .efficiency:  return Color(hex: "64D2FF")
        case .performance: return Color(hex: "BF5AF2")
        case .super:       return Color(hex: "FF6B6B")
        }
    }
}

// MARK: - Fan (hidden on fanless models)

private struct FanSection: View {
    @ObservedObject var model: SystemStatsModel
    var body: some View {
        SectionBox(icon: "fan", title: "Fan") {
            Row(label: "Speed") {
                HStack {
                    Text("\(model.fanRPM) RPM")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - GPU

private struct GPUSection: View {
    @ObservedObject var model: SystemStatsModel
    var body: some View {
        SectionBox(icon: "rectangle.3.group", title: "GPU  ·  \(model.gpuCoreCount) cores") {
            Row(label: "\(model.gpuMHz) MHz") {
                StatBar(pct: model.gpuUsage, color: Color(hex: "FF9F0A"))
            }
            HStack {
                Pill(icon: "thermometer", val: String(format: "%.0f°C", model.gpuTemp),
                     color: tempColor(model.gpuTemp))
                Spacer()
                Pill(icon: "bolt", val: String(format: "%.3f W", model.gpuPower),
                     color: Color(hex: "FFD60A"))
            }
            .padding(.top, 2)
        }
    }
}

// MARK: - Memory

private struct MemorySection: View {
    @ObservedObject var model: SystemStatsModel
    var body: some View {
        SectionBox(icon: "memorychip", title: "Memory") {
            Row(label: "\(fmtB(model.memUsed)) / \(fmtB(model.memTotal))") {
                StatBar(pct: model.memPct, color: Color(hex: "0A84FF"))
            }
            HStack(spacing: 16) {
                if model.dramBWAvailable {
                    KV("DRAM BW",  String(format: "%.1f GB/s", model.dramBW))
                }
                KV("Swap", model.swapTotal > 0
                    ? "\(fmtB(model.swapUsed)) / \(fmtB(model.swapTotal))" : "None")
            }
            .padding(.top, 2)
        }
    }
}

// MARK: - Battery

private struct BatterySection: View {
    @ObservedObject var model: SystemStatsModel

    var statusLabel: String {
        if model.batteryCharged  { return "Fully Charged" }
        if model.batteryCharging { return "Charging" }
        return "On Battery"
    }

    var batteryColor: Color {
        model.batteryPct < 20 ? Color(hex: "FF453A")
            : (model.batteryCharging || model.batteryCharged)
                ? Color(hex: "30D158") : Color(hex: "FFD60A")
    }

    var body: some View {
        SectionBox(icon: "battery.75percent", title: "Battery") {
            Row(label: statusLabel) {
                StatBar(pct: model.batteryPct, color: batteryColor)
            }
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    KV("Source",     model.batteryOnAC ? "AC Power" : "Battery")
                    KV("Remaining",  model.batteryTimeLeft)
                }
                GridRow {
                    KV("Adapter",    model.adapterWatts > 0
                        ? String(format: "%.0f W", model.adapterWatts) : "—")
                    KV("Charge rate",model.chargingWatts > 0
                        ? String(format: "%.1f W", model.chargingWatts) : "—")
                }
                GridRow {
                    KV("Temp",       model.batteryTempC > 0
                        ? String(format: "%.1f °C", model.batteryTempC) : "—")
                    KV("Cycles",     model.batteryCycles > 0
                        ? "\(model.batteryCycles)" : "—")
                }
                GridRow {
                    KV("Health",     "\(model.batteryHealthPct)%")
                    KV("Capacity",   model.batteryMaxMAh > 0
                        ? "\(model.batteryMaxMAh) / \(model.batteryDesignMAh) mAh" : "—")
                }
            }
            .padding(.top, 2)
        }
    }
}

// MARK: - Network + Disk

private struct NetworkDiskSection: View {
    @ObservedObject var model: SystemStatsModel
    @AppStorage(DashboardSection.network.defaultsKey) private var showNetwork = true
    @AppStorage(DashboardSection.disk.defaultsKey)    private var showDisk    = true

    var body: some View {
        if showNetwork || showDisk {
            SectionSeparator()
            HStack(spacing: 0) {
                if showNetwork {
                    SectionBox(icon: "wifi", title: "Network") {
                        IORow(icon: "arrow.down", val: fmtB(model.netInBps)  + "/s", color: Color(hex:"30D158"))
                        IORow(icon: "arrow.up",   val: fmtB(model.netOutBps) + "/s", color: Color(hex:"FF9F0A"))
                    }
                }
                if showNetwork && showDisk {
                    Rectangle().fill(Color.primary.opacity(0.08)).frame(width: 1)
                }
                if showDisk {
                    SectionBox(icon: "internaldrive", title: "Disk I/O") {
                        IORow(icon: "arrow.down", val: String(format: "%.0f KB/s", model.diskReadKBs),  color: Color(hex:"64D2FF"))
                        IORow(icon: "arrow.up",   val: String(format: "%.0f KB/s", model.diskWriteKBs), color: Color(hex:"FF9F0A"))
                    }
                }
            }
        }
    }
}

private struct IORow: View {
    let icon: String; let val: String; let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)).foregroundColor(color)
            Text(val)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

// MARK: - Power rails

private struct PowerSection: View {
    @ObservedObject var model: SystemStatsModel
    var body: some View {
        SectionBox(icon: "bolt.fill", title: "Power Rails") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 5) {
                PowerTile(label: "CPU",   val: model.cpuPower)
                PowerTile(label: "GPU",   val: model.gpuPower)
                if model.socEnergyAvailable {
                    PowerTile(label: "ANE",   val: model.anePower)
                    PowerTile(label: "DRAM",  val: model.dramPower)
                }
                PowerTile(label: "SYS",   val: model.sysPower)
                PowerTile(label: "TOTAL", val: model.totalPower, highlight: true)
            }
        }
    }
}

private struct PowerTile: View {
    let label: String; let val: Double; var highlight: Bool = false
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(highlight ? Color(hex:"FFD60A") : Color(hex:"888899"))
            Spacer()
            Text(String(format: val >= 1 ? "%.2f W" : "%.3f W", val))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(highlight ? Color(hex:"FFD60A") : .primary)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(Color.primary.opacity(highlight ? 0.07 : 0.03))
        .cornerRadius(6)
    }
}

// MARK: - Processes

private struct ProcessSection: View {
    @ObservedObject var model: SystemStatsModel
    var body: some View {
        SectionBox(icon: "list.bullet", title: "Top Processes") {
            HStack {
                Text("Process").frame(maxWidth: .infinity, alignment: .leading)
                Text("CPU").frame(width: 40, alignment: .trailing)
                Text("Memory").frame(width: 64, alignment: .trailing)
            }
            .font(.system(size: 9)).foregroundColor(.secondary)

            ForEach(model.topProcs) { p in
                HStack(spacing: 0) {
                    Text(p.name)
                        .font(.system(size: 11)).foregroundColor(.primary)
                        .lineLimit(1).truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(format: "%.1f%%", p.cpu))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(cpuClr(p.cpu))
                        .frame(width: 40, alignment: .trailing)
                    Text(fmtB(p.mem))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: "64D2FF"))
                        .frame(width: 64, alignment: .trailing)
                }
            }
        }
    }
    func cpuClr(_ v: Double) -> Color {
        v >= 50 ? Color(hex:"FF453A") : v >= 20 ? Color(hex:"FFD60A") : Color(hex:"30D158")
    }
}

// MARK: - Settings sheet

private struct MenuBarToggle: View {
    let item: MenuBarItem
    @AppStorage private var enabled: Bool

    init(item: MenuBarItem) {
        self.item = item
        _enabled = AppStorage(wrappedValue: false, item.defaultsKey)
    }

    var body: some View {
        Toggle(item.title, isOn: Binding(
            get: { enabled },
            set: { newValue in
                // Keep the status item clickable: refuse to uncheck the last item.
                if !newValue && MenuBarItem.enabledItems == [item] { return }
                enabled = newValue
            }))
            .toggleStyle(.checkbox)
            .font(.system(size: 12))
    }
}

private struct SectionToggle: View {
    let section: DashboardSection
    @AppStorage private var enabled: Bool

    init(section: DashboardSection) {
        self.section = section
        _enabled = AppStorage(wrappedValue: true, section.defaultsKey)
    }

    var body: some View {
        Toggle(section.title, isOn: $enabled)
            .toggleStyle(.checkbox)
            .font(.system(size: 12))
    }
}

struct SettingsSheet: View {
    @Binding var isPresented: Bool
    @AppStorage("openAtLogin")   var openAtLogin   = false
    @AppStorage("appTheme") private var appTheme = AppTheme.automatic.rawValue
    @ObservedObject private var updater = UpdateChecker.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.system(size: 16, weight: .bold)).foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Menu Bar")
                    .font(.system(size: 12, weight: .medium))
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading),
                                    GridItem(.flexible(), alignment: .leading)],
                          alignment: .leading, spacing: 6) {
                    ForEach(MenuBarItem.allCases) { MenuBarToggle(item: $0) }
                }
                Text("At least one item stays selected.")
                    .font(.system(size: 11)).foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Appearance")
                    .font(.system(size: 12, weight: .medium))
                Picker("Appearance", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label).tag(theme.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                Text("Automatic follows your Mac’s current appearance.")
                    .font(.system(size: 11)).foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Dashboard")
                    .font(.system(size: 12, weight: .medium))
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading),
                                    GridItem(.flexible(), alignment: .leading)],
                          alignment: .leading, spacing: 6) {
                    ForEach(DashboardSection.allCases) { SectionToggle(section: $0) }
                }
                Text("Hidden sections are not shown; processes, network, disk and battery also stop sampling.")
                    .font(.system(size: 11)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Open at Login", isOn: $openAtLogin)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "30D158")))
                    .onChange(of: openAtLogin) { enabled in
                        if enabled {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }
                Text("Automatically start MMetrics when you log in.")
                    .font(.system(size: 11)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Desktop Widget")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Button("Refresh Now") {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    .font(.system(size: 11))
                }
                Text("Right-click your desktop → Edit Widgets → find MMetrics. "
                     + "It refreshes on its own while MMetrics is running.")
                    .font(.system(size: 11)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MMetrics  v\(updater.currentVersion)")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(.primary)
                    Group {
                        switch updater.updatePhase {
                        case .idle:
                            if updater.updateAvailable {
                                Text("v\(updater.latestVersion) available")
                                    .foregroundColor(Color(hex: "FF9F0A"))
                            } else {
                                Text("Apple Silicon  ·  macOS 13+  ·  MIT")
                                    .foregroundColor(.secondary)
                            }
                        case .downloading:
                            Text("Downloading v\(updater.latestVersion)…")
                                .foregroundColor(Color(hex: "FF9F0A"))
                        case .installing:
                            Text("Installing…")
                                .foregroundColor(Color(hex: "FF9F0A"))
                        case .readyToRelaunch:
                            Text("Ready — relaunch to apply")
                                .foregroundColor(Color(hex: "30D158"))
                        case .failed(let msg):
                            Text(msg)
                                .foregroundColor(Color(hex: "FF453A"))
                        }
                    }
                    .font(.system(size: 10))
                }
                Spacer()
                Group {
                    switch updater.updatePhase {
                    case .idle:
                        HStack(spacing: 6) {
                            if updater.updateAvailable {
                                Button("Update") { updater.startUpdate() }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color(hex: "FF9F0A"))
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            Button("Done") { isPresented = false }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(hex: "0A84FF"))
                        }
                    case .downloading:
                        VStack(alignment: .trailing, spacing: 3) {
                            ProgressView(value: updater.downloadFraction)
                                .progressViewStyle(.linear)
                                .tint(Color(hex: "FF9F0A"))
                                .frame(width: 80)
                            Text("\(Int(updater.downloadFraction * 100))%")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    case .installing:
                        ProgressView()
                            .scaleEffect(0.75)
                            .tint(Color(hex: "FF9F0A"))
                    case .readyToRelaunch:
                        Button("Relaunch") { updater.relaunch() }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: "30D158"))
                            .font(.system(size: 12, weight: .semibold))
                    case .failed:
                        Button("Dismiss") { updater.dismissUpdateError() }
                            .buttonStyle(.bordered)
                            .font(.system(size: 12))
                    }
                }
            }
        }
        .padding(22).frame(width: 360)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)
    }
}

// MARK: - Reusable atoms

private struct SectionBox<Content: View>: View {
    let icon: String; let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "888899"))
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "888899")).tracking(0.6)
            }
            content
        }
        .padding(.horizontal, 16).padding(.vertical, 11)
    }
}

private struct Row<R: View>: View {
    let label: String; @ViewBuilder let right: R
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11)).foregroundColor(.secondary)
                .frame(width: 130, alignment: .leading).lineLimit(1)
            right
        }
    }
}

private struct StatBar: View {
    let pct: Int; var color: Color = Color(hex: "30D158")
    private var barColor: Color {
        pct >= 85 ? Color(hex:"FF453A") : pct >= 60 ? Color(hex:"FFD60A") : color
    }
    var body: some View {
        HStack(spacing: 6) {
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3).fill(barColor)
                        .frame(width: g.size.width * CGFloat(min(pct,100)) / 100)
                        .animation(.easeInOut(duration: 0.4), value: pct)
                }
            }
            .frame(height: 7)
            Text("\(pct)%")
                .font(.system(size: 11, design: .monospaced)).foregroundColor(.primary)
                .frame(width: 32, alignment: .trailing)
        }
    }
}

private struct CoreTile: View {
    let index: Int; let pct: Double; let tint: Color
    var color: Color {
        pct >= 85 ? Color(hex:"FF453A") : pct >= 60 ? Color(hex:"FFD60A") : tint
    }
    var body: some View {
        HStack(spacing: 5) {
            Text("C\(index)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(color.opacity(0.7))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: 22, alignment: .leading)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.primary.opacity(0.08))
                    RoundedRectangle(cornerRadius: 2).fill(color)
                        .frame(width: g.size.width * CGFloat(min(pct,100)) / 100)
                        .animation(.easeInOut(duration: 0.4), value: pct)
                }
            }
            .frame(height: 5)
            Text("\(Int(pct))%")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: 26, alignment: .trailing)
        }
    }
}

private struct Pill: View {
    let icon: String; let val: String; let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9))
            Text(val).font(.system(size: 10, design: .monospaced))
        }
        .foregroundColor(color)
    }
}

private struct KV: View {
    let k: String; let v: String
    init(_ k: String, _ v: String) { self.k = k; self.v = v }
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(k).font(.system(size: 9)).foregroundColor(.secondary)
            Text(v).font(.system(size: 11, design: .monospaced)).foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Helpers

private func fmtB(_ b: Int64) -> String {
    let d = Double(b)
    if d >= 1_073_741_824 { return String(format: "%.1f GB", d/1_073_741_824) }
    if d >= 1_048_576     { return String(format: "%.1f MB", d/1_048_576) }
    if d >= 1_024         { return String(format: "%.0f KB", d/1_024) }
    return "\(b) B"
}

private func tempColor(_ t: Double) -> Color {
    t >= 80 ? Color(hex:"FF453A") : t >= 65 ? Color(hex:"FFD60A") : Color(hex:"888899")
}

// MARK: - Hex colour helper

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double((int)       & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
