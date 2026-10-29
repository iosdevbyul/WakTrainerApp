import SwiftUI
import WakTrainerCoreModels

/// Review-only view. A later PR must implement verified authenticated writes.
struct ProfileConflictReviewView: View {
    let snapshot: ProfileConflictSnapshot
    let onDismiss: () -> Void
    @State private var choice: ProfileConflictChoice?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("로컬과 서버의 프로필이 달라요.")
                        .font(.headline)
                    Text("선택 내용은 미리보기이며, 아직 어느 쪽 데이터도 변경하지 않습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    profileSection("이 기기에 저장된 정보", profile: snapshot.local)
                    profileSection("서버에 저장된 정보", profile: snapshot.remote)

                    Text("향후 적용할 정보 선택")
                        .font(.headline)
                    Picker("적용할 정보", selection: $choice) {
                        Text("선택하지 않음").tag(ProfileConflictChoice?.none)
                        Text("로컬 정보 유지").tag(ProfileConflictChoice?.some(.keepLocal))
                        Text("서버 정보 사용").tag(ProfileConflictChoice?.some(.useServer))
                        Text("나중에 결정").tag(ProfileConflictChoice?.some(.postpone))
                    }
                    .pickerStyle(.inline)
                    Text("현재 버전에서는 서버 업로드나 로컬 덮어쓰기를 실행하지 않습니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("프로필 비교")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기", action: onDismiss)
                }
            }
        }
    }

    private func profileSection(_ title: String, profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            LabeledContent("성별", value: profile.gender.rawValue)
            LabeledContent("생년월일", value: profile.birthDate.formatted(
                .dateTime.year().month(.twoDigits).day(.twoDigits)
            ))
            LabeledContent("키", value: String(format: "%.1f cm", profile.heightCm))
            LabeledContent("몸무게", value: String(format: "%.1f kg", profile.weightKg))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}
