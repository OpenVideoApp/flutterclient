dynamic getOptionalVar(Map<String, dynamic> json, String prop, dynamic fallback) {
  return json[prop] != null ? json[prop] : fallback;
}

int getOptionalInt(Map<String, dynamic> json, String prop) {
  return getOptionalVar(json, prop, 0) as int;
}

bool getOptionalBool(Map<String, dynamic> json, String prop) {
  return getOptionalVar(json, prop, false) as bool;
}