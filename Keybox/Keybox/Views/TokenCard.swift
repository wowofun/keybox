import SwiftUI

struct TokenCard: View {
    let token: OTPToken
    @State private var copied = false
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            HStack(spacing: 16) {
                // Icon / Initial
                ZStack {
                    Circle()
                        .fill(
                            Theme.primaryGradient
                        )
                        .frame(width: 50, height: 50)
                    
                    Text(String(token.issuer.prefix(1)).uppercased())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .shadow(color: Theme.shadowColor, radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(token.issuer)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(token.accountName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCode(token.currentCode))
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText(countsDown: false))
                    
                    // Circular Progress
                    CircularProgressView(period: token.period, date: context.date)
                        .frame(width: 20, height: 20)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    copyToClipboard()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(copied ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: copied)
        }
    }
    
    private func formatCode(_ code: String) -> String {
        guard code.count == 6 else { return code }
        let firstHalf = code.prefix(3)
        let secondHalf = code.suffix(3)
        return "\(firstHalf) \(secondHalf)"
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = token.currentCode
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation {
            copied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                copied = false
            }
        }
    }
}

struct CircularProgressView: View {
    var period: TimeInterval
    var date: Date
    
    var body: some View {
        let progress = calculateProgress(date: date)
        
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    progress > 0.2 ? Theme.primary : Color.red,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
        }
    }
    
    private func calculateProgress(date: Date) -> Double {
        let time = date.timeIntervalSince1970
        let remaining = period - (time.truncatingRemainder(dividingBy: period))
        return remaining / period
    }
}
