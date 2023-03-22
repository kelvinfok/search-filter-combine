//
//  ViewController.swift
//  combine-search
//
//  Created by Kelvin Fok on 23/3/23.
//

import UIKit
import Combine
import SDWebImage

class SearchController: UITableViewController {
  
  private var movies: [Movie] = []
  @Published private var filtered: [Movie] = []
  
  private lazy var searchController: UISearchController = {
    let controller = UISearchController(searchResultsController: nil)
    controller.searchResultsUpdater = self
    controller.obscuresBackgroundDuringPresentation = false
    controller.searchBar.placeholder = "Filter results"
    return controller
  }()
  
  private var cancellables = Set<AnyCancellable>()
  
  override func loadView() {
    super.loadView()
    observe()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupTableView()
    fetchProducts()
    setupNavigation()
  }
  
  private func setupTableView() {
    tableView.contentInset = .init(top: -20, left: 0, bottom: 0, right: 0)
  }
  
  private func fetchProducts() {
    
    let group = DispatchGroup()
    var temp = [Movie]()
    
    for page in 1...10 {
      group.enter()
      var url: URL {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name:"s", value: "marvel"),
            URLQueryItem(name:"apikey", value: "9f43a994"),
            URLQueryItem(name:"page", value: "\(page)")
        ]
        return URL(string: "https://www.omdbapi.com/" + components.string!)!
      }
      
      URLSession.shared.dataTaskPublisher(for: url)
        .map { $0.data }
        .decode(type: MoviesResponse.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .sink { completion in
          // don't need to handle
        } receiveValue: { response in
          temp.append(contentsOf: response.result)
          group.leave()
        }.store(in: &cancellables)
    }
    
    group.notify(queue: .main) {
      self.movies = temp
      self.filtered = self.movies
    }
  }
  
  private func setupNavigation() {
    navigationItem.searchController = searchController
  }
  
  private func observe() {
    $filtered
      .receive(on: DispatchQueue.main)
      .sink { [weak self ] _ in
        self?.tableView.reloadData()
    }.store(in: &cancellables)
  }
}

extension SearchController {
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filtered.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! MovieTableViewCell
    let movie = filtered[indexPath.item]
    cell.configure(movie: movie)
    return cell
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 144
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return String(format: "%d results found", filtered.count)
  }
}

extension SearchController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    guard let query = searchController.searchBar.text,
          !query.isEmpty else {
      self.filtered = self.movies
      return }
    self.filtered = self.movies.filter { $0.title.lowercased().contains(query.lowercased()) }
  }
}
