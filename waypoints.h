/*
 * debootstrap waypoints for run-debootstrap. See the README for docs.
 */
struct waypoint {
	int endpercent;
	char *progress_id;
};
static struct waypoint waypoints[] = {
	{ 0,    "START" },	/* dummy entry, required */
	{ 1,	"DOWNREL" },	/* downloading release files; very quick */
	{ 5,	"DOWNPKGS" },	/* downloading packages files; time varies
	                           by bandwidth (and size); low granularity */
	{ 10,	"SIZEDEBS" },   /* getting packages sizes; high granularity */
	{ 25,	"DOWNDEBS" },   /* downloading packages; run time varies by
				   bandwidth; high granularity */
	{ 45,	"EXTRACTPKGS" },/* extracting the core packages */
	{ 100,	"INSTBASE" },	/* installing the base system
				   (currently has very bad granularity) */
	{ 0,	NULL },		/* last entry, required */
};
