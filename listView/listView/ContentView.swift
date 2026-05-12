//
//  ContentView.swift
//  listView
//
//  Created by Abhijit Sahoo on 07/05/26.
//

import SwiftUI
struct Pet: Identifiable{
    
    enum Kind {
        case cat
        case dog
        case fish
        case bird
        case lizard
        case turtle
        case rabbit
        case bug
        
        var SystemImage: String {
            switch self {
            case .cat: return "cat.fill"
            case .dog: return "dog.fill"
            case .fish: return "fish.fill"
            case .bird: return "bird.fill"
            case .lizard: return "lizard.fill"
            case .turtle: return "tortoise.fill"
            case .rabbit: return "rabbit.fill"
            case .bug: return "ant.fill"
            }
        }
    }
    
    let id = UUID()
    var name: String
    var kind: Kind
    var trick: String
    
    static let samplePets = [
        Pet(name: "Whiskers", kind: .cat, trick: "Tightrope walking"),
        Pet(name: "Roofus", kind: .dog, trick: "Home runs"),
        Pet(name: "Bubbles", kind: .fish, trick: "100m freestyle"),
        Pet(name: "Mango", kind: .bird, trick: "Basketball dunk"),
        Pet(name: "Ziggy", kind: .lizard, trick: "Parkour"),
        Pet(name: "Sheldon", kind: .turtle, trick: "Kickflip"),
        Pet(name: "Chirpy", kind: .bug, trick: "Canon in D")
    ]
    
}

struct petRowView: View{
    var pet: Pet
    
    var body: some View {
        HStack {
            Label(pet.name , systemImage: pet.kind.SystemImage)
            Spacer()
            Text(pet.trick)
                .foregroundStyle(.secondary)
        }
    }
}

struct RatingView: View {
    @State private var rating = 5
    
    var body: some View {
        HStack {
            Button("Decrease", systemImage: "minus.circle"){
                withAnimation{
                    rating -= 1
                }
            }
            .disabled(rating == 0)
            .labelStyle(.iconOnly)
            
            Text(rating, format: .number.precision(.integerLength(2)))
                .contentTransition(.numericText(value: Double (rating)))
                .font(.title.bold())
            
            Button("Increase", systemImage: "plus.circle"){
                withAnimation{
                    rating += 1
                }
            }
            .disabled(rating == 10)
            .labelStyle(.iconOnly)
        }
        .font(.title2)
    }
}

struct ContentView: View {
    @State private var pets = Pet.samplePets
    
    var body: some View {
        VStack {
            
            RatingView()
                .padding(.top)
            
            Button("Add Pet"){
                pets.append(
                    Pet(name: "Toby", kind: .dog, trick: "WWDC Presenter")
                )
            }
            .buttonStyle(.glassProminent)
        }
        
        List(pets) { pet in
            petRowView(pet: pet)
        }
        
    }
}

#Preview {
    ContentView()
}
