#ifndef __TILECOOL_H__
#define __TILECOOL_H__

struct TileType {
  // slopes, defined in the interval [0; 1] which is mapped to the actual tile
  // height. 0 represents a tile slope that is completely at the bottom and 1 at
  // the top. A (0, 0) is therefore an empty tile and (1, 1).
  // All values outside [0; 1] will be clamped.
  double top_l;  // Top left
  double top_r;  // Top right
};

typedef unsigned char Tile;

struct Map {
  Tile * data;
  TileType type_table[256];
  int rows;
  int cols;
  // Tile size
  int tw;
  int th;
  // Position
  double x;
  double y;
};

// Axis aligned bounding box
struct AABB {
  // Position
  double x;
  double y;
  // Spatial extension
  int w;
  int h;
  // Velocity
  double vx;
  double vy;
};

struct Collision {
  // x-axis collision, -1 for no collision
  double x;
  // y-axis collision, -1 for no collision
  double y;
};

/**
 * Performs future sweep collision detection for a number of entities.
 * 
 * \map is a reference to the tilemap with defined slopes for each tile.
 * \entities is an array of AABB with the necessary spatial information that is
 * needed for the collision detection.
 * \collision is an array intended to contain the result of each collision. The
 * entry will correspond to that for \entities for each object.
 * \size the number of entities which must be tested. \entities and \collisions
 * must contain at least \size entries.
 *
 * returns 0 on success or something else on error (TBD).
*/
int futureMapCollision(const Map * map, const AABB * entities,
                        Collision * collisions, const int size);

#endif  // __TILECOOL_H__
