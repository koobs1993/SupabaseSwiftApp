import Foundation
import Supabase
import SwiftUI

@MainActor
class CharacterDetailViewModel: ObservableObject {
    @Published var character: Character?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var relatedCharacters: [Character] = []
    @Published var problems: [Problem] = []
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let supabase: SupabaseClient
    private let characterId: Int
    
    init(supabase: SupabaseClient, characterId: Int) {
        self.supabase = supabase
        self.characterId = characterId
    }
    
    func fetchCharacter() async {
        isLoading = true
        error = nil
        
        do {
            let query = supabase.database
                .from("characters")
                .select("""
                    *,
                    characterproblems:characterproblems(
                        problems(*)
                    )
                """)
                .eq("character_id", characterId)
                .eq("is_active", true)
                .single()
            
            let response: Character = try await query.execute().value
            character = response
            
            // Extract problems from character problems
            if let characterProblems = response.problems {
                problems = characterProblems
                await fetchRelatedCharacters(problems: characterProblems)
            }
        } catch {
            self.error = error
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
        
        isLoading = false
    }
    
    private func fetchRelatedCharacters(problems: [Problem]) async {
        do {
            let problemIds = problems.map { $0.problemId }
            
            let query = supabase.database
                .from("characterproblems")
                .select("""
                    characters!inner(*)
                """)
                .in_("problem_id", values: problemIds)
                .neq("characters.character_id", characterId)
                .eq("characters.is_active", true)
                .limit(5)
            
            let response: [Character] = try await query.execute().value
            relatedCharacters = Array(Set(response))
        } catch {
            print("Error fetching related characters: \(error)")
            self.errorMessage = "Failed to load related characters"
            self.showError = true
        }
    }
    
    func shareCharacter() {
        guard let character = character else { return }
        
        let text = """
        Check out \(character.name) in our app!
        
        \(character.bio)
        
        Download the app to learn more about \(character.name) and other characters.
        """
        
        let activityViewController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
    
    func retryFetch() async {
        await fetchCharacter()
    }
} 