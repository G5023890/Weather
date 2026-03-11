import SwiftUI

@main
struct WeatherApp: App {
    @StateObject private var viewModel = WeatherMenuBarViewModel.live()

    var body: some Scene {
        MenuBarExtra {
            WeatherMenuBarContentView(viewModel: viewModel)
                .task {
                    await viewModel.handlePopoverAppear()
                }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel.menuBarSymbolName)
                Text(viewModel.menuBarText)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .frame(minWidth: 120)
        }
        .menuBarExtraStyle(.window)
    }
}
