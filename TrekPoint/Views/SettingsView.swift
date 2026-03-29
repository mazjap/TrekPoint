import SwiftUI
import Dependencies

// MARK: - Settings View

struct SettingsView: View {
    @Bindable private var settings: AppSettings
    
    @Environment(\.dismiss) private var dismiss
    
    init() {
        @Dependency(\.appSettings) var appSettings
        self.settings = appSettings
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.08)
                    .ignoresSafeArea()
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.06),
                                Color.clear,
                                Color.blue.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        headerView
                        
                        settingsSection(
                            title: "Map",
                            icon: "map",
                            iconColor: .blue
                        ) {
                            MapStylePicker(selection: $settings.mapStyle)
                        }
                        
                        settingsSection(
                            title: "Terrain",
                            icon: "mountain.2",
                            iconColor: .yellow
                        ) {
                            MapTerrainPicker(isTerrainSelected: $settings.isTerrainEnabled, isContourSelected: $settings.isContourEnabled)
                        }
                        
                        settingsSection(
                            title: "Units",
                            icon: "ruler",
                            iconColor: .orange
                        ) {
                            DistanceUnitPicker(selection: $settings.distanceUnit)
                        }
                        
                        settingsSection(
                            title: "GPS",
                            icon: "location.fill",
                            iconColor: .green
                        ) {
                            GPSAccuracyPicker(selection: $settings.gpsAccuracy)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.orange)
                        .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Color(white: 0.08), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Customize your trek experience")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(0.5)
        }
        .padding(.top, 12)
    }
    
    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1.5)
            }
            
            content()
        }
    }
}

private struct MapTerrainPicker: View {
    @Binding var isTerrainSelected: Bool
    @Binding var isContourSelected: Bool
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            SelectableSettingsCard(systemIconName: isTerrainSelected ? "mountain.2.fill" : "mountain.2", label: "3D Terrain", sublabel: nil, isSelected: isTerrainSelected, usesCheckmark: false) {
                isTerrainSelected.toggle()
            }
            
            SelectableSettingsCard(systemIconName: "waveform", label: "Contour lines", sublabel: nil, isSelected: isContourSelected, usesCheckmark: false) {
                isContourSelected.toggle()
            }
        }
    }
}

private struct MapStylePicker: View {
    @Binding var selection: MapStyleSetting
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(MapStyleSetting.allCases, id: \.rawValue) { style in
                MapStyleCard(style: style, isSelected: selection == style) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = style
                    }
                }
            }
        }
    }
}

private struct SelectableSettingsCard: View {
    let systemIconName: String
    let label: String
    let sublabel: String?
    let isSelected: Bool
    let usesCheckmark: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                Image(systemName: systemIconName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(isSelected ? .orange : .white.opacity(0.4))
                    .frame(height: 16)
                    .padding(.trailing, 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                    
                    if let sublabel {
                        Text(sublabel)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                
                Spacer(minLength: 0)
                
                if isSelected && usesCheckmark {
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.orange)
                        .frame(height: 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.orange.opacity(0.12) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.orange.opacity(0.5) : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

private struct MapStyleCard: View {
    let style: MapStyleSetting
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        SelectableSettingsCard(systemIconName: style.icon, label: style.label, sublabel: nil, isSelected: isSelected, usesCheckmark: true, onTap: onTap)
    }
}

private struct DistanceUnitPicker: View {
    @Binding var selection: DistanceUnit
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(DistanceUnit.allCases, id: \.rawValue) { unit in
                DistanceUnitCard(unit: unit, isSelected: selection == unit) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = unit
                    }
                }
            }
        }
    }
}

private struct DistanceUnitCard: View {
    let unit: DistanceUnit
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        SelectableSettingsCard(systemIconName: unit.icon, label: unit.label, sublabel: unit.sublabel, isSelected: isSelected, usesCheckmark: true, onTap: onTap)
    }
}

private struct GPSAccuracyPicker: View {
    @Binding var selection: GPSAccuracyMode
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(GPSAccuracyMode.allCases, id: \.rawValue) { mode in
                GPSAccuracyCard(mode: mode, isSelected: selection == mode) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = mode
                    }
                }
            }
        }
    }
}

private struct GPSAccuracyCard: View {
    let mode: GPSAccuracyMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? mode.accentColor.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? mode.accentColor : .white.opacity(0.3))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.label)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                    
                    Text(mode.sublabel)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineLimit(1)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? mode.accentColor : Color.white.opacity(0.2),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(mode.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? mode.accentColor.opacity(0.08) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? mode.accentColor.opacity(0.4) : Color.white.opacity(0.07),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    SettingsView()
}
