import SwiftUI
import UIKit

/**
 * 通用组件层。
 *
 * 铁律：界面上任何「写死的中文」都必须通过 `TrText` / `AppButton` / `AppField` 走 I18n.t()，
 * 不允许直接 `Text("中文")`。用户输入的影片名、场号、器材型号等属于数据，按行业惯例保留原文。
 * 泰文行高较大，所有文本统一带 lineSpacing；单行标签带 minimumScaleFactor，
 * 避免英文 / 泰文长文案把相邻控件挤到重叠。
 */

struct TrText: View {
    @EnvironmentObject private var store: AppStore

    let zh: String
    var size: CGFloat = 13
    var color: Color = Pal.text
    var weight: Font.Weight = .regular
    var mono: Bool = false
    var align: TextAlignment = .leading
    var lineLimit: Int? = nil

    /// 全文统一按位置参数调用（TrText("文案", size: ...)），
    /// 这里显式声明无标签构造器，避免默认 memberwise init 要求 zh: 标签而全员报错。
    init(_ zh: String,
         size: CGFloat = 13,
         color: Color = Pal.text,
         weight: Font.Weight = .regular,
         mono: Bool = false,
         align: TextAlignment = .leading,
         lineLimit: Int? = nil) {
        self.zh = zh
        self.size = size
        self.color = color
        self.weight = weight
        self.mono = mono
        self.align = align
        self.lineLimit = lineLimit
    }

    var body: some View {
        Text(I18n.shared.t(zh, store.lang))
            .font(mono
                  ? .system(size: size, weight: weight, design: .monospaced)
                  : .system(size: size, weight: weight))
            .foregroundColor(color)
            .lineSpacing(store.lang.lineSpacing)
            .lineLimit(lineLimit)
            .minimumScaleFactor(lineLimit == 1 ? 0.60 : 1.0)
            .multilineTextAlignment(align)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// 数据文本（型号 / 场号 / 时码 / 用户输入）：与 Android `Components.kt` 的 Text 包装一致，
/// 同样经过 I18n.t()，因此界面固定文案（如「实时合成」）会随语言切换；
/// 词典里没有的专有名词（片名、人名、标准号）按行业惯例保留原文。
struct DataText: View {
    @EnvironmentObject private var store: AppStore
    let value: String
    var size: CGFloat = 13
    var color: Color = Pal.text
    var weight: Font.Weight = .regular
    var mono: Bool = true
    var lineLimit: Int? = 1

    var body: some View {
        Text(I18n.shared.t(value, store.lang))
            .font(mono
                  ? .system(size: size, weight: weight, design: .monospaced)
                  : .system(size: size, weight: weight))
            .foregroundColor(color)
            .lineSpacing(store.lang.lineSpacing)
            .lineLimit(lineLimit)
            .minimumScaleFactor(lineLimit == 1 ? 0.60 : 1.0)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct SectionHeader: View {
    let zh: String
    var hint: String? = nil

    var body: some View {
        // hint 独占一行：泰文 / 英文说明往往比中文长一倍，
        // 塞在标题右侧会把标题挤压到重叠或缩成不可读的小字。
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Rectangle().fill(Pal.accent).frame(width: 3, height: 13)
                    .cornerRadius(2)
                TrText(zh, size: 13.5, color: Pal.text, weight: .bold, lineLimit: 1)
                Spacer(minLength: 0)
            }
            if let h = hint {
                TrText(h, size: 10.5, color: Pal.text3, lineLimit: 2)
                    .padding(.leading, 11)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
}

struct AppField: View {
    @EnvironmentObject private var store: AppStore
    let labelZh: String
    @Binding var text: String
    var placeholderZh: String = ""
    var mono: Bool = false
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            TrText(labelZh, size: 10, color: Pal.text3, weight: .semibold, lineLimit: 1)
            TextField(I18n.shared.t(placeholderZh, store.lang), text: $text)
                .font(mono
                      ? .system(size: 13, weight: .medium, design: .monospaced)
                      : .system(size: 13, weight: .medium))
                .foregroundColor(Pal.text)
                .keyboardType(keyboard)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Pal.bgInput)
                .clipShape(RoundedRectangle(cornerRadius: D.radiusSm))
                .overlay(
                    RoundedRectangle(cornerRadius: D.radiusSm)
                        .stroke(Pal.borderStrong, lineWidth: 1)
                )
        }
    }
}

struct AppButton: View {
    let zh: String
    var primary: Bool = true
    var enabled: Bool = true
    var compact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TrText(zh, size: compact ? 11.5 : 13, color: enabled ? .white : Pal.textMute,
                   weight: .bold, lineLimit: 1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 8 : 11)
                .background(enabled ? (primary ? Pal.accent : Pal.bgElevated) : Pal.bgPanel2)
                .clipShape(RoundedRectangle(cornerRadius: D.radiusSm))
                .overlay(
                    RoundedRectangle(cornerRadius: D.radiusSm)
                        .stroke(enabled && !primary ? Pal.borderStrong : .clear, lineWidth: 1)
                )
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

func toneColor(_ tone: TagTone) -> Color {
    switch tone {
    case .neutral: return Pal.text3
    case .ok:      return Pal.ok
    case .info:    return Pal.info
    case .warn:    return Pal.warn
    case .accent:  return Pal.accent
    }
}

struct TagChip: View {
    let zh: String
    var tone: TagTone = .neutral
    var on: Bool = false

    var body: some View {
        TrText(zh, size: 11, color: on ? toneColor(tone) : Pal.text2, weight: .bold, lineLimit: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(on ? toneColor(tone).opacity(0.16) : Pal.bgInput)
            .clipShape(RoundedRectangle(cornerRadius: D.radiusSm))
            .overlay(
                RoundedRectangle(cornerRadius: D.radiusSm)
                    .stroke(on ? toneColor(tone).opacity(0.7) : Pal.borderStrong, lineWidth: 1)
            )
    }
}

struct StatTile: View {
    let value: String
    let labelZh: String
    var tone: TagTone = .neutral

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            DataText(value: value, size: 19, color: toneColor(tone), weight: .bold)
            TrText(labelZh, size: 10.5, color: Pal.text3, lineLimit: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(Pal.bgInput)
        .clipShape(RoundedRectangle(cornerRadius: D.radiusSm))
        .overlay(
            RoundedRectangle(cornerRadius: D.radiusSm)
                .stroke(Pal.border, lineWidth: 1)
        )
    }
}

/// 键值行：标签翻译、值是项目数据（不翻译）
struct MetaRow: View {
    let labelZh: String
    let value: String
    var mono: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            TrText(labelZh, size: 11, color: Pal.text3, lineLimit: 2)
                .frame(width: 100, alignment: .leading)
            DataText(value: value.isEmpty ? "—" : value, size: 12.5,
                     color: value.isEmpty ? Pal.textMute : Pal.text,
                     mono: mono, lineLimit: 2)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }
}

/// 结果行：标签翻译、计算值也走词典（避免「档 / 无需 ND」等中英夹杂）。
/// 所有页面共用，宽度自适应，泰文长标签允许换行不挤压数值。
struct ResultRow: View {
    let labelZh: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            TrText(labelZh, size: 11.5, color: Pal.text3, lineLimit: 2)
                .frame(minWidth: 82, maxWidth: 120, alignment: .leading)
            TrText(value, size: 13, color: Pal.text, weight: .semibold, mono: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
    }
}

struct EmptyHint: View {
    let zh: String
    var body: some View {
        TrText(zh, size: 12, color: Pal.text3, align: .center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
    }
}
