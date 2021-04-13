//
//  pathfinder.swift
//  ARKitPersistence
//
//  Created by Niles Bernabe on 4/13/21.
//

protocol PathfinderDataSource: NSObjectProtocol {
  func walkableAdjacentTilesCoordsForTileCoord(tileCoord: TileCoord) -> [TileCoord]
  func costToMoveFromTileCoord(fromTileCoord: TileCoord, toAdjacentTileCoord toTileCoord: TileCoord) -> Int
}

/** A pathfinder based on the A* algorithm to find the shortest path between two locations */
class AStarPathfinder {
  weak var dataSource: PathfinderDataSource?

  func shortestPathFromTileCoord(fromTileCoord: TileCoord, toTileCoord: TileCoord) -> [TileCoord]? {
    // placeholder: move immediately to the destination coordinate
    return [toTileCoord]
  }
}
