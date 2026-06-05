import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 920 || proxy.size.height < 620

            ZStack {
                ConsoleBackground()

                ScrollView {
                    Group {
                        if isCompact {
                            VStack(spacing: 18) {
                                LoginSignalPanel(isCompact: true)
                                    .frame(maxWidth: 460)

                                LoginCardView(viewModel: viewModel)
                                    .frame(maxWidth: 430)
                            }
                        } else {
                            HStack(spacing: 28) {
                                LoginSignalPanel()
                                    .frame(maxWidth: 460)

                                LoginCardView(viewModel: viewModel)
                                    .frame(maxWidth: 430)
                            }
                        }
                    }
                    .padding(isCompact ? 18 : 42)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct LoginSignalPanel: View {
    var isCompact = false

    var body: some View {
        ConsolePanel(padding: isCompact ? 18 : 28, spacing: isCompact ? 16 : 22) {
            VStack(alignment: .leading, spacing: isCompact ? 10 : 12) {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.2.fill")
                        .font(.system(size: isCompact ? 21 : 26, weight: .semibold))
                        .foregroundStyle(AppTheme.amber)
                        .frame(width: isCompact ? 42 : 48, height: isCompact ? 42 : 48)
                        .background(AppTheme.amber.opacity(0.13), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lepro Control")
                            .font(.system(size: isCompact ? 22 : 26, weight: .semibold, design: .rounded))
                        Text("macOS command center")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: isCompact ? 4 : 18)

                VStack(alignment: .leading, spacing: 10) {
                    Text("CONTROL SURFACE")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.cyan)
                    Text("Tiras WiFi, escenas y segmentos en una interfaz propia.")
                        .font(.system(size: isCompact ? 26 : 34, weight: .semibold, design: .rounded))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LightStripPreview(isCompact: isCompact)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                    MetricPill(title: "Cloud", value: "EU", tint: AppTheme.cyan)
                    MetricPill(title: "Control", value: "MQTT", tint: AppTheme.violet)
                    MetricPill(title: "Secure", value: "Keychain", tint: AppTheme.success)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

struct LightStripPreview: View {
    var isCompact = false

    private let colors: [Color] = [
        .red, .orange, .yellow, AppTheme.success, AppTheme.cyan, .blue, AppTheme.violet, .pink
    ]

    var body: some View {
        VStack(spacing: 9) {
            ForEach(0..<(isCompact ? 2 : 3), id: \.self) { row in
                HStack(spacing: 7) {
                    ForEach(0..<12, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors[(index + row * 2) % colors.count])
                            .frame(height: isCompact ? 16 : 20)
                            .opacity(0.68 + Double((index + row) % 3) * 0.10)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        }
    }
}

struct LoginCardView: View {
    @ObservedObject var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        ConsolePanel(padding: 24, spacing: 22) {
            header
            fields
            actions
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Acceso")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
            Text("Inicia sesion con tu cuenta Lepro Cloud.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: 13) {
            ConsoleTextField(
                title: "Cuenta",
                systemImage: "person.crop.circle",
                placeholder: "Email o telefono",
                text: $viewModel.email
            )
            .focused($focusedField, equals: .email)
            .disabled(viewModel.isLoading)

            ConsoleSecureField(
                title: "Contrasena",
                systemImage: "lock",
                placeholder: "Password",
                text: $viewModel.password
            )
            .focused($focusedField, equals: .password)
            .disabled(viewModel.isLoading)
            .onSubmit {
                Task { await viewModel.login() }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    Picker("Region", selection: $viewModel.region) {
                        ForEach(LeproRegion.allCases) { region in
                            Text(region.displayName).tag(region)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    ConsoleTextField(
                        title: "Idioma",
                        systemImage: "globe",
                        placeholder: "en",
                        text: $viewModel.language
                    )
                    .frame(width: 116)
                    .disabled(viewModel.isLoading)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Picker("Region", selection: $viewModel.region) {
                        ForEach(LeproRegion.allCases) { region in
                            Text(region.displayName).tag(region)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    ConsoleTextField(
                        title: "Idioma",
                        systemImage: "globe",
                        placeholder: "en",
                        text: $viewModel.language
                    )
                    .disabled(viewModel.isLoading)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                ErrorBannerView(message: errorMessage)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.errorMessage)
    }

    private var actions: some View {
        Button {
            Task { await viewModel.login() }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(viewModel.isLoading ? "Conectando" : "Entrar")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
        }
        .buttonStyle(LiquidButtonStyle())
        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: AppTheme.cyan.opacity(viewModel.isLoading ? 0.08 : 0.28), radius: 22, x: 0, y: 12)
        .disabled(viewModel.isLoading)
    }
}

struct ConsoleTextField: View {
    let title: String
    let systemImage: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                }
        }
    }
}

struct ConsoleSecureField: View {
    let title: String
    let systemImage: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            SecureField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                }
        }
    }
}
