import SwiftUI
import SDWebImageSwiftUI

struct CharacterDetailView: View {
    @StateObject private var viewModel: CharacterDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(supabase: SupabaseClient, characterId: Int) {
        _viewModel = StateObject(wrappedValue: CharacterDetailViewModel(supabase: supabase, characterId: characterId))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    LoadingView()
                } else if let character = viewModel.character {
                    // Character Header
                    CharacterHeaderView(character: character)
                    
                    // Bio Section
                    CharacterBioSection(character: character)
                    
                    // Problems Section
                    if !viewModel.problems.isEmpty {
                        CharacterProblemsSection(problems: viewModel.problems)
                    }
                    
                    // Related Characters
                    if !viewModel.relatedCharacters.isEmpty {
                        RelatedCharactersSection(characters: viewModel.relatedCharacters)
                    }
                    
                    // Share Button
                    Button {
                        viewModel.shareCharacter()
                    } label: {
                        Label("Share Character", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("Retry") {
                Task {
                    await viewModel.retryFetch()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            await viewModel.fetchCharacter()
        }
    }
}

// MARK: - Supporting Views
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
            Text("Loading character details...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 100)
    }
}

private struct CharacterHeaderView: View {
    let character: Character
    
    var body: some View {
        VStack(spacing: 16) {
            WebImage(url: URL(string: character.imageUrl))
                .resizable()
                .placeholder {
                    Color.gray.opacity(0.2)
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .scaledToFill()
                .frame(width: 150, height: 150)
                .clipShape(Circle())
                .shadow(radius: 5)
            
            Text(character.name)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding(.horizontal)
    }
}

private struct CharacterBioSection: View {
    let character: Character
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .padding(.horizontal)
            
            Text(character.bio)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct CharacterProblemsSection: View {
    let problems: [Problem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Problems")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(problems) { problem in
                        ProblemCard(problem: problem)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct ProblemCard: View {
    let problem: Problem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let iconUrl = problem.iconUrl {
                WebImage(url: URL(string: iconUrl))
                    .resizable()
                    .placeholder {
                        Color.gray.opacity(0.2)
                    }
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
            
            Text(problem.name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(problem.shortDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if let tags = problem.tags {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .frame(width: 200)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

private struct RelatedCharactersSection: View {
    let characters: [Character]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Characters")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(characters) { character in
                        NavigationLink {
                            CharacterDetailView(
                                supabase: .shared,
                                characterId: character.id
                            )
                        } label: {
                            RelatedCharacterCard(character: character)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct RelatedCharacterCard: View {
    let character: Character
    
    var body: some View {
        VStack(spacing: 8) {
            WebImage(url: URL(string: character.imageUrl))
                .resizable()
                .placeholder {
                    Color.gray.opacity(0.2)
                }
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            
            Text(character.name)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(width: 100)
    }
} 