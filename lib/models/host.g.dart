// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'host.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Host _$HostFromJson(Map<String, dynamic> json) => Host(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  username: json['username'] as String,
  password: json['password'] as String?,
  rootAccess: json['rootAccess'] as bool? ?? false,
  privateKey: json['privateKey'] as String?,
  actions:
      (json['actions'] as List<dynamic>?)
          ?.map((e) => HostAction.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  authorizedKeys:
      (json['authorizedKeys'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$HostToJson(Host instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'username': instance.username,
  'password': instance.password,
  'rootAccess': instance.rootAccess,
  'privateKey': instance.privateKey,
  'actions': instance.actions,
  'authorizedKeys': instance.authorizedKeys,
};

HostAction _$HostActionFromJson(Map<String, dynamic> json) => HostAction(
  name: json['name'] as String,
  command: json['command'] as String,
);

Map<String, dynamic> _$HostActionToJson(HostAction instance) =>
    <String, dynamic>{'name': instance.name, 'command': instance.command};
