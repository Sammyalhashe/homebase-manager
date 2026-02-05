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
);

Map<String, dynamic> _$HostToJson(Host instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'username': instance.username,
  'password': instance.password,
  'rootAccess': instance.rootAccess,
  'privateKey': instance.privateKey,
};
