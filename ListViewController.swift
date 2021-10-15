//
//  ListViewController.swift
//  iOS Bootcamp Challenge
//
//  Created by Jorge Benavides on 26/09/21.
//

import UIKit
import SVProgressHUD

class ListViewController: UICollectionViewController {

    private var pokemons: [Pokemon] = []
    private var resultPokemons: [Pokemon] = []

    // TODO: Use UserDefaults to pre-load the latest search at start

    private var latestSearch: String?

    lazy private var searchController: SearchBar = {
        let searchController = SearchBar("Search a pokemon", delegate: nil)
        searchController.text = latestSearch
        searchController.showsCancelButton = !searchController.isSearchBarEmpty
        return searchController
    }()
    
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }

    private var isFirstLauch: Bool = true

    //Loading indicator when the app first launches and has no pokemons
    var spinner = UIActivityIndicatorView(style: .large)
    
    private var shouldShowLoader: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchController.searchResultsUpdater = self
        setup()
        setupUI()
    }

    // MARK: Setup

    private func setup() {
        title = "Pokédex"

        // Customize navigation bar.
        guard let navbar = self.navigationController?.navigationBar else { return }

        navbar.tintColor = .black
        navbar.titleTextAttributes = [.foregroundColor: UIColor.black]
        navbar.prefersLargeTitles = true

        // Set up the searchController parameters.
        navigationItem.searchController = searchController
        definesPresentationContext = true

        refresh()
    }

    private func setupUI() {

        // Set up the collection view.
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.indicatorStyle = .white
        
        // Set up spinner view.
        createSpinnerView()

        // Set up the refresh control as part of the collection view when it's pulled to refresh.
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.sendSubviewToBack(refreshControl)
    }
    
    func createSpinnerView() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .red
        spinner.startAnimating()
        collectionView.addSubview(spinner)
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func removeSpinnerView() {
        spinner.stopAnimating()
        spinner.removeFromSuperview()
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFiltering {
            return resultPokemons.count
        }
        
        return pokemons.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PokeCell.identifier, for: indexPath) as? PokeCell
        else { preconditionFailure("Failed to load collection view cell") }
        cell.pokemon = resultPokemons[indexPath.item]
        return cell
    }

    // MARK: - Navigation

    //Handle navigation to detail view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? UICollectionViewCell {
                    let i = self.collectionView.indexPath(for: cell)!.row
                    if segue.identifier == "goDetailViewControllerSegue" {
                        let vc = segue.destination as! DetailViewController
                        vc.pokemon = resultPokemons[i]
                    }
        }
    }

    // MARK: - UI Hooks

    @objc func refresh() {
        shouldShowLoader = true

        var pokemons: [Pokemon] = []

        // TODO: Wait for all requests to finish before updating the collection view
        PokeAPI.shared.get(url: "pokemon?limit=30", onCompletion: { (list: PokemonList?, _) in
            guard let list = list else { return }
            list.results.forEach { result in
                PokeAPI.shared.get(url: "/pokemon/\(result.id)/", onCompletion: { (pokemon: Pokemon?, _) in
                    guard let pokemon = pokemon else { return }
                    pokemons.append(pokemon)
                    self.pokemons = pokemons
                    self.didRefresh()
                })
            }
        })
        
    }

    private func didRefresh() {
        shouldShowLoader = false

        guard
            let collectionView = collectionView,
            let refreshControl = collectionView.refreshControl
        else { return }

        refreshControl.endRefreshing()

        filterContentForSearchText("")
    }

}

// MARK: - UISearchViewController
extension ListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        // filter with a simple contains searched text
        resultPokemons = pokemons
            .filter {
                searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())
            }
            .sorted {
                $0.id < $1.id
            }

        collectionView.reloadData()
        removeSpinnerView()
    }

}
