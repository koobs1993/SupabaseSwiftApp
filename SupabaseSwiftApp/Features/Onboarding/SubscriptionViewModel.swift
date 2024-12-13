import Foundation
import StoreKit

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var product: Product?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var purchaseCompleted = false
    
    private let productId = "com.yourapp.weekly.subscription"
    
    func loadProduct() async {
        isLoading = true
        error = nil
        
        do {
            let products = try await Product.products(for: [productId])
            product = products.first
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func startFreeTrial() async {
        guard let product = product else { return }
        isLoading = true
        error = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchaseCompleted = true
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
} 