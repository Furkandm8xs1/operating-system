#include <stdio.h>

typedef struct {
    float x, y, z;
} Vec3;

typedef struct {
    const char *name;
    int damage;
    int ammo;
} Weapon;

typedef struct {
    float yaw;    /* yatay bakis acisi */
    float pitch;  /* dikey bakis acisi */
} Aim;

typedef struct {
    const char *name;
    int health;
    Vec3 pos;
    Aim aim;
    Weapon weapon;
} Person;

Vec3 vec_add(Vec3 a, Vec3 b) {
    Vec3 r = { a.x + b.x, a.y + b.y, a.z + b.z };
    return r;
}

void move(Person *p, Vec3 dir) {
    p->pos = vec_add(p->pos, dir);
}

void set_aim(Person *p, float yaw, float pitch) {
    p->aim.yaw = yaw;
    p->aim.pitch = pitch;
}

int shoot(Person *shooter, Person *target) {
    if (shooter->weapon.ammo <= 0) return 0;
    shooter->weapon.ammo--;
    target->health -= shooter->weapon.damage;
    if (target->health < 0) target->health = 0;
    return 1;
}

int main(void) {
    Person a = { "T",  100, {0, 0, 0},  {0, 0}, {"AK47", 30, 30} };
    Person b = { "CT", 100, {10, 0, 5}, {0, 0}, {"M4A1", 25, 30} };

    Vec3 step = { 1, 0, 0 };
    move(&a, step);
    set_aim(&a, 90.0f, 0.0f);
    shoot(&a, &b);

    printf("%s pos=(%.1f,%.1f,%.1f) ammo=%d\n", a.name, a.pos.x, a.pos.y, a.pos.z, a.weapon.ammo);
    printf("%s health=%d\n", b.name, b.health);
    return 0;
}
