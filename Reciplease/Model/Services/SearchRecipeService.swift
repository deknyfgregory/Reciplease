//
//  SearchRecipeService.swift
//  Reciplease
//
//  Created by Gregory De knyf on 07/11/2018.
//  Copyright © 2018 De knyf Gregory. All rights reserved.
//

import Foundation
import Alamofire

class SearchRecipeService {
    
    static var shared = SearchRecipeService()
    private init() {}
    
    func SearchRecipe(with ingredient: [String], page: Int, callback: @escaping (Bool, [Recipe]?, String?) -> Void) {

        //Pagination
        let maxResult = 10
        let start = page * maxResult
        
        //Parameters for request, ingredients and requirePictures
        let parameters: Parameters = ["q":ingredient, "maxResult":maxResult, "start": start]

        //Header for request, contain app id and app key
        let header: HTTPHeaders = ["X-Yummly-App-ID":"252dd2e6",
                                   "X-Yummly-App-Key":"afa5977aac4ad8225e73955c196b581e"]

        //Api endpoint
        guard let url = URL(string: "https://api.yummly.com/v1/api/recipes") else { return }
        
        Alamofire.request(url,
                          method: .get,
                          parameters: parameters,
                          headers: header)
            .validate()
            .responseJSON { (response) in
                
                guard response.result.isSuccess else {
                    print("Error while fetching data.")
                    callback(false, nil, "Error while fetching data")
                    return
                }

                guard let data = response.data else {
                    callback(false, nil,  "No data")
                    return
                }
                
                guard let responseJSON = try? JSONDecoder().decode(SearchRecipeDecodable.self, from: data) else {
                    callback(false, nil,  "Error parse JSON")
                        return
                }
                
                if responseJSON.matches.isEmpty {
                    callback(false, nil, "Aucune recette")
                    return
                }
                
                
                callback(true, self.getRecipeDataFrom(responseJSON), nil)

        }
    }

    private func getRecipeDataFrom(_ parsedData: SearchRecipeDecodable) -> [Recipe] {
        var recipes: [Recipe] = []
        for recipe in parsedData.matches {
            
            var backgroundImage: UIImage = UIImage(named: "DefaultImageRecipe")!
            
            if let url = URL(string: recipe.imageUrlsBySize.the90) {
                if let data = try? Data(contentsOf: url) {
                    backgroundImage = UIImage(data: data)!
                }
            }

            recipes.append(Recipe(
                id: recipe.id,
                name: recipe.recipeName,
                ingredients: recipe.ingredients,
                timeToPrepareInSeconde: recipe.totalTimeInSeconds,
                rating: recipe.rating,
                smallImage: backgroundImage,
                bigImage: nil,
                sourceRecipeUrl: nil)
            )
        }
        return recipes
    }
}
