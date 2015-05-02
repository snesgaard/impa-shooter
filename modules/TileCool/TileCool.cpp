#include "./TileCool.h"

static Collision futureSingleCollision(const Map * map, const AABB entity) {
  struct Collision output;

  output.
}

int futureMapCollision(const Map * map, const AABB * entities,
                        Collision * collisions, const int size) {
  for (int i = 0; i < size; ++i) {
    collisions[i] = futureSingleCollision(map, entities[i]);
  }
  return 0;
}
