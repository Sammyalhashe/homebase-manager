import 'package:json_annotation/json_annotation.dart';

part 'host.g.dart';

@JsonSerializable()
class Host {
  final String id;
  final String name;
  final String address;
  final String username;
  final String? password;
  final bool rootAccess;
  final String? privateKey;

  Host({
    required this.id,
    required this.name,
    required this.address,
    required this.username,
    this.password,
    this.rootAccess = false,
    this.privateKey,
  });

  factory Host.fromJson(Map<String, dynamic> json) => _$HostFromJson(json);
  Map<String, dynamic> toJson() => _$HostToJson(this);

  factory Host.fromYaml(Map<dynamic, dynamic> yaml) {
    return Host(
      id: yaml['id']?.toString() ?? yaml['name']?.toString() ?? '',
      name: yaml['name']?.toString() ?? 'Unknown',
      address: yaml['address']?.toString() ?? '',
      username: yaml['username']?.toString() ?? 'root',
      password: yaml['password']?.toString(),
      rootAccess: yaml['root_access'] == true || yaml['rootAccess'] == true,
      privateKey: yaml['private_key']?.toString(),
    );
  }
}
