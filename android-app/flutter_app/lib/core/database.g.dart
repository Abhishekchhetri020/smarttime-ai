// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SubjectsTable extends Subjects
    with TableInfo<$SubjectsTable, SubjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _abbrMeta = const VerificationMeta('abbr');
  @override
  late final GeneratedColumn<String> abbr = GeneratedColumn<String>(
      'abbr', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roomTypeIdMeta =
      const VerificationMeta('roomTypeId');
  @override
  late final GeneratedColumn<int> roomTypeId = GeneratedColumn<int>(
      'room_type_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0xFF0B3D91));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, abbr, groupId, roomTypeId, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(Insertable<SubjectRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('abbr')) {
      context.handle(
          _abbrMeta, abbr.isAcceptableOrUnknown(data['abbr']!, _abbrMeta));
    } else if (isInserting) {
      context.missing(_abbrMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    }
    if (data.containsKey('room_type_id')) {
      context.handle(
          _roomTypeIdMeta,
          roomTypeId.isAcceptableOrUnknown(
              data['room_type_id']!, _roomTypeIdMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      abbr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}abbr'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id']),
      roomTypeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}room_type_id']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class SubjectRow extends DataClass implements Insertable<SubjectRow> {
  final String id;
  final String name;
  final String abbr;
  final String? groupId;
  final int? roomTypeId;
  final int color;
  const SubjectRow(
      {required this.id,
      required this.name,
      required this.abbr,
      this.groupId,
      this.roomTypeId,
      required this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['abbr'] = Variable<String>(abbr);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || roomTypeId != null) {
      map['room_type_id'] = Variable<int>(roomTypeId);
    }
    map['color'] = Variable<int>(color);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      name: Value(name),
      abbr: Value(abbr),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      roomTypeId: roomTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(roomTypeId),
      color: Value(color),
    );
  }

  factory SubjectRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      abbr: serializer.fromJson<String>(json['abbr']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      roomTypeId: serializer.fromJson<int?>(json['roomTypeId']),
      color: serializer.fromJson<int>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'abbr': serializer.toJson<String>(abbr),
      'groupId': serializer.toJson<String?>(groupId),
      'roomTypeId': serializer.toJson<int?>(roomTypeId),
      'color': serializer.toJson<int>(color),
    };
  }

  SubjectRow copyWith(
          {String? id,
          String? name,
          String? abbr,
          Value<String?> groupId = const Value.absent(),
          Value<int?> roomTypeId = const Value.absent(),
          int? color}) =>
      SubjectRow(
        id: id ?? this.id,
        name: name ?? this.name,
        abbr: abbr ?? this.abbr,
        groupId: groupId.present ? groupId.value : this.groupId,
        roomTypeId: roomTypeId.present ? roomTypeId.value : this.roomTypeId,
        color: color ?? this.color,
      );
  SubjectRow copyWithCompanion(SubjectsCompanion data) {
    return SubjectRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      abbr: data.abbr.present ? data.abbr.value : this.abbr,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      roomTypeId:
          data.roomTypeId.present ? data.roomTypeId.value : this.roomTypeId,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('abbr: $abbr, ')
          ..write('groupId: $groupId, ')
          ..write('roomTypeId: $roomTypeId, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, abbr, groupId, roomTypeId, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.abbr == this.abbr &&
          other.groupId == this.groupId &&
          other.roomTypeId == this.roomTypeId &&
          other.color == this.color);
}

class SubjectsCompanion extends UpdateCompanion<SubjectRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> abbr;
  final Value<String?> groupId;
  final Value<int?> roomTypeId;
  final Value<int> color;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.abbr = const Value.absent(),
    this.groupId = const Value.absent(),
    this.roomTypeId = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String id,
    required String name,
    required String abbr,
    this.groupId = const Value.absent(),
    this.roomTypeId = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        abbr = Value(abbr);
  static Insertable<SubjectRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? abbr,
    Expression<String>? groupId,
    Expression<int>? roomTypeId,
    Expression<int>? color,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (abbr != null) 'abbr': abbr,
      if (groupId != null) 'group_id': groupId,
      if (roomTypeId != null) 'room_type_id': roomTypeId,
      if (color != null) 'color': color,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? abbr,
      Value<String?>? groupId,
      Value<int?>? roomTypeId,
      Value<int>? color,
      Value<int>? rowid}) {
    return SubjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      abbr: abbr ?? this.abbr,
      groupId: groupId ?? this.groupId,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      color: color ?? this.color,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (abbr.present) {
      map['abbr'] = Variable<String>(abbr.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (roomTypeId.present) {
      map['room_type_id'] = Variable<int>(roomTypeId.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('abbr: $abbr, ')
          ..write('groupId: $groupId, ')
          ..write('roomTypeId: $roomTypeId, ')
          ..write('color: $color, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClassesTable extends Classes with TableInfo<$ClassesTable, ClassRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _abbrMeta = const VerificationMeta('abbr');
  @override
  late final GeneratedColumn<String> abbr = GeneratedColumn<String>(
      'abbr', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, abbr];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'classes';
  @override
  VerificationContext validateIntegrity(Insertable<ClassRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('abbr')) {
      context.handle(
          _abbrMeta, abbr.isAcceptableOrUnknown(data['abbr']!, _abbrMeta));
    } else if (isInserting) {
      context.missing(_abbrMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      abbr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}abbr'])!,
    );
  }

  @override
  $ClassesTable createAlias(String alias) {
    return $ClassesTable(attachedDatabase, alias);
  }
}

class ClassRow extends DataClass implements Insertable<ClassRow> {
  final String id;
  final String name;
  final String abbr;
  const ClassRow({required this.id, required this.name, required this.abbr});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['abbr'] = Variable<String>(abbr);
    return map;
  }

  ClassesCompanion toCompanion(bool nullToAbsent) {
    return ClassesCompanion(
      id: Value(id),
      name: Value(name),
      abbr: Value(abbr),
    );
  }

  factory ClassRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      abbr: serializer.fromJson<String>(json['abbr']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'abbr': serializer.toJson<String>(abbr),
    };
  }

  ClassRow copyWith({String? id, String? name, String? abbr}) => ClassRow(
        id: id ?? this.id,
        name: name ?? this.name,
        abbr: abbr ?? this.abbr,
      );
  ClassRow copyWithCompanion(ClassesCompanion data) {
    return ClassRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      abbr: data.abbr.present ? data.abbr.value : this.abbr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('abbr: $abbr')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, abbr);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.abbr == this.abbr);
}

class ClassesCompanion extends UpdateCompanion<ClassRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> abbr;
  final Value<int> rowid;
  const ClassesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.abbr = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassesCompanion.insert({
    required String id,
    required String name,
    required String abbr,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        abbr = Value(abbr);
  static Insertable<ClassRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? abbr,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (abbr != null) 'abbr': abbr,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? abbr,
      Value<int>? rowid}) {
    return ClassesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      abbr: abbr ?? this.abbr,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (abbr.present) {
      map['abbr'] = Variable<String>(abbr.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('abbr: $abbr, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DivisionsTable extends Divisions
    with TableInfo<$DivisionsTable, DivisionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DivisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _classIdMeta =
      const VerificationMeta('classId');
  @override
  late final GeneratedColumn<String> classId = GeneratedColumn<String>(
      'class_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES classes (id)'));
  @override
  List<GeneratedColumn> get $columns => [id, name, classId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'divisions';
  @override
  VerificationContext validateIntegrity(Insertable<DivisionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DivisionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DivisionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_id'])!,
    );
  }

  @override
  $DivisionsTable createAlias(String alias) {
    return $DivisionsTable(attachedDatabase, alias);
  }
}

class DivisionRow extends DataClass implements Insertable<DivisionRow> {
  final String id;
  final String name;
  final String classId;
  const DivisionRow(
      {required this.id, required this.name, required this.classId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['class_id'] = Variable<String>(classId);
    return map;
  }

  DivisionsCompanion toCompanion(bool nullToAbsent) {
    return DivisionsCompanion(
      id: Value(id),
      name: Value(name),
      classId: Value(classId),
    );
  }

  factory DivisionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DivisionRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      classId: serializer.fromJson<String>(json['classId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'classId': serializer.toJson<String>(classId),
    };
  }

  DivisionRow copyWith({String? id, String? name, String? classId}) =>
      DivisionRow(
        id: id ?? this.id,
        name: name ?? this.name,
        classId: classId ?? this.classId,
      );
  DivisionRow copyWithCompanion(DivisionsCompanion data) {
    return DivisionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      classId: data.classId.present ? data.classId.value : this.classId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DivisionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('classId: $classId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, classId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DivisionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.classId == this.classId);
}

class DivisionsCompanion extends UpdateCompanion<DivisionRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> classId;
  final Value<int> rowid;
  const DivisionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.classId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DivisionsCompanion.insert({
    required String id,
    required String name,
    required String classId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        classId = Value(classId);
  static Insertable<DivisionRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? classId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (classId != null) 'class_id': classId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DivisionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? classId,
      Value<int>? rowid}) {
    return DivisionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      classId: classId ?? this.classId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DivisionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('classId: $classId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeachersTable extends Teachers
    with TableInfo<$TeachersTable, TeacherRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeachersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _abbreviationMeta =
      const VerificationMeta('abbreviation');
  @override
  late final GeneratedColumn<String> abbreviation = GeneratedColumn<String>(
      'abbreviation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _maxPeriodsPerDayMeta =
      const VerificationMeta('maxPeriodsPerDay');
  @override
  late final GeneratedColumn<int> maxPeriodsPerDay = GeneratedColumn<int>(
      'max_periods_per_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxGapsPerDayMeta =
      const VerificationMeta('maxGapsPerDay');
  @override
  late final GeneratedColumn<int> maxGapsPerDay = GeneratedColumn<int>(
      'max_gaps_per_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, abbreviation, maxPeriodsPerDay, maxGapsPerDay];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teachers';
  @override
  VerificationContext validateIntegrity(Insertable<TeacherRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('abbreviation')) {
      context.handle(
          _abbreviationMeta,
          abbreviation.isAcceptableOrUnknown(
              data['abbreviation']!, _abbreviationMeta));
    } else if (isInserting) {
      context.missing(_abbreviationMeta);
    }
    if (data.containsKey('max_periods_per_day')) {
      context.handle(
          _maxPeriodsPerDayMeta,
          maxPeriodsPerDay.isAcceptableOrUnknown(
              data['max_periods_per_day']!, _maxPeriodsPerDayMeta));
    }
    if (data.containsKey('max_gaps_per_day')) {
      context.handle(
          _maxGapsPerDayMeta,
          maxGapsPerDay.isAcceptableOrUnknown(
              data['max_gaps_per_day']!, _maxGapsPerDayMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeacherRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeacherRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      abbreviation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}abbreviation'])!,
      maxPeriodsPerDay: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}max_periods_per_day']),
      maxGapsPerDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_gaps_per_day']),
    );
  }

  @override
  $TeachersTable createAlias(String alias) {
    return $TeachersTable(attachedDatabase, alias);
  }
}

class TeacherRow extends DataClass implements Insertable<TeacherRow> {
  final String id;
  final String name;
  final String abbreviation;
  final int? maxPeriodsPerDay;
  final int? maxGapsPerDay;
  const TeacherRow(
      {required this.id,
      required this.name,
      required this.abbreviation,
      this.maxPeriodsPerDay,
      this.maxGapsPerDay});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['abbreviation'] = Variable<String>(abbreviation);
    if (!nullToAbsent || maxPeriodsPerDay != null) {
      map['max_periods_per_day'] = Variable<int>(maxPeriodsPerDay);
    }
    if (!nullToAbsent || maxGapsPerDay != null) {
      map['max_gaps_per_day'] = Variable<int>(maxGapsPerDay);
    }
    return map;
  }

  TeachersCompanion toCompanion(bool nullToAbsent) {
    return TeachersCompanion(
      id: Value(id),
      name: Value(name),
      abbreviation: Value(abbreviation),
      maxPeriodsPerDay: maxPeriodsPerDay == null && nullToAbsent
          ? const Value.absent()
          : Value(maxPeriodsPerDay),
      maxGapsPerDay: maxGapsPerDay == null && nullToAbsent
          ? const Value.absent()
          : Value(maxGapsPerDay),
    );
  }

  factory TeacherRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeacherRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      abbreviation: serializer.fromJson<String>(json['abbreviation']),
      maxPeriodsPerDay: serializer.fromJson<int?>(json['maxPeriodsPerDay']),
      maxGapsPerDay: serializer.fromJson<int?>(json['maxGapsPerDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'abbreviation': serializer.toJson<String>(abbreviation),
      'maxPeriodsPerDay': serializer.toJson<int?>(maxPeriodsPerDay),
      'maxGapsPerDay': serializer.toJson<int?>(maxGapsPerDay),
    };
  }

  TeacherRow copyWith(
          {String? id,
          String? name,
          String? abbreviation,
          Value<int?> maxPeriodsPerDay = const Value.absent(),
          Value<int?> maxGapsPerDay = const Value.absent()}) =>
      TeacherRow(
        id: id ?? this.id,
        name: name ?? this.name,
        abbreviation: abbreviation ?? this.abbreviation,
        maxPeriodsPerDay: maxPeriodsPerDay.present
            ? maxPeriodsPerDay.value
            : this.maxPeriodsPerDay,
        maxGapsPerDay:
            maxGapsPerDay.present ? maxGapsPerDay.value : this.maxGapsPerDay,
      );
  TeacherRow copyWithCompanion(TeachersCompanion data) {
    return TeacherRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      abbreviation: data.abbreviation.present
          ? data.abbreviation.value
          : this.abbreviation,
      maxPeriodsPerDay: data.maxPeriodsPerDay.present
          ? data.maxPeriodsPerDay.value
          : this.maxPeriodsPerDay,
      maxGapsPerDay: data.maxGapsPerDay.present
          ? data.maxGapsPerDay.value
          : this.maxGapsPerDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeacherRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('abbreviation: $abbreviation, ')
          ..write('maxPeriodsPerDay: $maxPeriodsPerDay, ')
          ..write('maxGapsPerDay: $maxGapsPerDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, abbreviation, maxPeriodsPerDay, maxGapsPerDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeacherRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.abbreviation == this.abbreviation &&
          other.maxPeriodsPerDay == this.maxPeriodsPerDay &&
          other.maxGapsPerDay == this.maxGapsPerDay);
}

class TeachersCompanion extends UpdateCompanion<TeacherRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> abbreviation;
  final Value<int?> maxPeriodsPerDay;
  final Value<int?> maxGapsPerDay;
  final Value<int> rowid;
  const TeachersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.abbreviation = const Value.absent(),
    this.maxPeriodsPerDay = const Value.absent(),
    this.maxGapsPerDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeachersCompanion.insert({
    required String id,
    required String name,
    required String abbreviation,
    this.maxPeriodsPerDay = const Value.absent(),
    this.maxGapsPerDay = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        abbreviation = Value(abbreviation);
  static Insertable<TeacherRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? abbreviation,
    Expression<int>? maxPeriodsPerDay,
    Expression<int>? maxGapsPerDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (abbreviation != null) 'abbreviation': abbreviation,
      if (maxPeriodsPerDay != null) 'max_periods_per_day': maxPeriodsPerDay,
      if (maxGapsPerDay != null) 'max_gaps_per_day': maxGapsPerDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeachersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? abbreviation,
      Value<int?>? maxPeriodsPerDay,
      Value<int?>? maxGapsPerDay,
      Value<int>? rowid}) {
    return TeachersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      maxPeriodsPerDay: maxPeriodsPerDay ?? this.maxPeriodsPerDay,
      maxGapsPerDay: maxGapsPerDay ?? this.maxGapsPerDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (abbreviation.present) {
      map['abbreviation'] = Variable<String>(abbreviation.value);
    }
    if (maxPeriodsPerDay.present) {
      map['max_periods_per_day'] = Variable<int>(maxPeriodsPerDay.value);
    }
    if (maxGapsPerDay.present) {
      map['max_gaps_per_day'] = Variable<int>(maxGapsPerDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeachersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('abbreviation: $abbreviation, ')
          ..write('maxPeriodsPerDay: $maxPeriodsPerDay, ')
          ..write('maxGapsPerDay: $maxGapsPerDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeacherUnavailabilityTable extends TeacherUnavailability
    with TableInfo<$TeacherUnavailabilityTable, TeacherUnavailabilityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeacherUnavailabilityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teacherIdMeta =
      const VerificationMeta('teacherId');
  @override
  late final GeneratedColumn<String> teacherId = GeneratedColumn<String>(
      'teacher_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES teachers (id)'));
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
      'day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<int> period = GeneratedColumn<int>(
      'period', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
      'state', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [id, teacherId, day, period, state];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teacher_unavailability';
  @override
  VerificationContext validateIntegrity(
      Insertable<TeacherUnavailabilityRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('teacher_id')) {
      context.handle(_teacherIdMeta,
          teacherId.isAcceptableOrUnknown(data['teacher_id']!, _teacherIdMeta));
    } else if (isInserting) {
      context.missing(_teacherIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('period')) {
      context.handle(_periodMeta,
          period.isAcceptableOrUnknown(data['period']!, _periodMeta));
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeacherUnavailabilityRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeacherUnavailabilityRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      teacherId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}teacher_id'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      period: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}state'])!,
    );
  }

  @override
  $TeacherUnavailabilityTable createAlias(String alias) {
    return $TeacherUnavailabilityTable(attachedDatabase, alias);
  }
}

class TeacherUnavailabilityRow extends DataClass
    implements Insertable<TeacherUnavailabilityRow> {
  final String id;
  final String teacherId;
  final int day;
  final int period;
  final int state;
  const TeacherUnavailabilityRow(
      {required this.id,
      required this.teacherId,
      required this.day,
      required this.period,
      required this.state});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['teacher_id'] = Variable<String>(teacherId);
    map['day'] = Variable<int>(day);
    map['period'] = Variable<int>(period);
    map['state'] = Variable<int>(state);
    return map;
  }

  TeacherUnavailabilityCompanion toCompanion(bool nullToAbsent) {
    return TeacherUnavailabilityCompanion(
      id: Value(id),
      teacherId: Value(teacherId),
      day: Value(day),
      period: Value(period),
      state: Value(state),
    );
  }

  factory TeacherUnavailabilityRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeacherUnavailabilityRow(
      id: serializer.fromJson<String>(json['id']),
      teacherId: serializer.fromJson<String>(json['teacherId']),
      day: serializer.fromJson<int>(json['day']),
      period: serializer.fromJson<int>(json['period']),
      state: serializer.fromJson<int>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teacherId': serializer.toJson<String>(teacherId),
      'day': serializer.toJson<int>(day),
      'period': serializer.toJson<int>(period),
      'state': serializer.toJson<int>(state),
    };
  }

  TeacherUnavailabilityRow copyWith(
          {String? id, String? teacherId, int? day, int? period, int? state}) =>
      TeacherUnavailabilityRow(
        id: id ?? this.id,
        teacherId: teacherId ?? this.teacherId,
        day: day ?? this.day,
        period: period ?? this.period,
        state: state ?? this.state,
      );
  TeacherUnavailabilityRow copyWithCompanion(
      TeacherUnavailabilityCompanion data) {
    return TeacherUnavailabilityRow(
      id: data.id.present ? data.id.value : this.id,
      teacherId: data.teacherId.present ? data.teacherId.value : this.teacherId,
      day: data.day.present ? data.day.value : this.day,
      period: data.period.present ? data.period.value : this.period,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeacherUnavailabilityRow(')
          ..write('id: $id, ')
          ..write('teacherId: $teacherId, ')
          ..write('day: $day, ')
          ..write('period: $period, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, teacherId, day, period, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeacherUnavailabilityRow &&
          other.id == this.id &&
          other.teacherId == this.teacherId &&
          other.day == this.day &&
          other.period == this.period &&
          other.state == this.state);
}

class TeacherUnavailabilityCompanion
    extends UpdateCompanion<TeacherUnavailabilityRow> {
  final Value<String> id;
  final Value<String> teacherId;
  final Value<int> day;
  final Value<int> period;
  final Value<int> state;
  final Value<int> rowid;
  const TeacherUnavailabilityCompanion({
    this.id = const Value.absent(),
    this.teacherId = const Value.absent(),
    this.day = const Value.absent(),
    this.period = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeacherUnavailabilityCompanion.insert({
    required String id,
    required String teacherId,
    required int day,
    required int period,
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        teacherId = Value(teacherId),
        day = Value(day),
        period = Value(period);
  static Insertable<TeacherUnavailabilityRow> custom({
    Expression<String>? id,
    Expression<String>? teacherId,
    Expression<int>? day,
    Expression<int>? period,
    Expression<int>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teacherId != null) 'teacher_id': teacherId,
      if (day != null) 'day': day,
      if (period != null) 'period': period,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeacherUnavailabilityCompanion copyWith(
      {Value<String>? id,
      Value<String>? teacherId,
      Value<int>? day,
      Value<int>? period,
      Value<int>? state,
      Value<int>? rowid}) {
    return TeacherUnavailabilityCompanion(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      day: day ?? this.day,
      period: period ?? this.period,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teacherId.present) {
      map['teacher_id'] = Variable<String>(teacherId.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (period.present) {
      map['period'] = Variable<int>(period.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeacherUnavailabilityCompanion(')
          ..write('id: $id, ')
          ..write('teacherId: $teacherId, ')
          ..write('day: $day, ')
          ..write('period: $period, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonsTable extends Lessons with TableInfo<$LessonsTable, LessonRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectIdMeta =
      const VerificationMeta('subjectId');
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
      'subject_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES subjects (id)'));
  static const VerificationMeta _periodsPerWeekMeta =
      const VerificationMeta('periodsPerWeek');
  @override
  late final GeneratedColumn<int> periodsPerWeek = GeneratedColumn<int>(
      'periods_per_week', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> teacherIds =
      GeneratedColumn<String>('teacher_ids', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>($LessonsTable.$converterteacherIds);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> classIds =
      GeneratedColumn<String>('class_ids', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>($LessonsTable.$converterclassIds);
  static const VerificationMeta _classIdMeta =
      const VerificationMeta('classId');
  @override
  late final GeneratedColumn<String> classId = GeneratedColumn<String>(
      'class_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _classDivisionIdMeta =
      const VerificationMeta('classDivisionId');
  @override
  late final GeneratedColumn<String> classDivisionId = GeneratedColumn<String>(
      'class_division_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES divisions (id)'));
  static const VerificationMeta _countPerWeekMeta =
      const VerificationMeta('countPerWeek');
  @override
  late final GeneratedColumn<int> countPerWeek = GeneratedColumn<int>(
      'count_per_week', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _fixedDayMeta =
      const VerificationMeta('fixedDay');
  @override
  late final GeneratedColumn<int> fixedDay = GeneratedColumn<int>(
      'fixed_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _fixedPeriodMeta =
      const VerificationMeta('fixedPeriod');
  @override
  late final GeneratedColumn<int> fixedPeriod = GeneratedColumn<int>(
      'fixed_period', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _roomTypeIdMeta =
      const VerificationMeta('roomTypeId');
  @override
  late final GeneratedColumn<int> roomTypeId = GeneratedColumn<int>(
      'room_type_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _relationshipTypeMeta =
      const VerificationMeta('relationshipType');
  @override
  late final GeneratedColumn<int> relationshipType = GeneratedColumn<int>(
      'relationship_type', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _relationshipGroupKeyMeta =
      const VerificationMeta('relationshipGroupKey');
  @override
  late final GeneratedColumn<String> relationshipGroupKey =
      GeneratedColumn<String>('relationship_group_key', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        subjectId,
        periodsPerWeek,
        teacherIds,
        classIds,
        classId,
        classDivisionId,
        countPerWeek,
        isPinned,
        fixedDay,
        fixedPeriod,
        roomTypeId,
        relationshipType,
        relationshipGroupKey
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lessons';
  @override
  VerificationContext validateIntegrity(Insertable<LessonRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(_subjectIdMeta,
          subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta));
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('periods_per_week')) {
      context.handle(
          _periodsPerWeekMeta,
          periodsPerWeek.isAcceptableOrUnknown(
              data['periods_per_week']!, _periodsPerWeekMeta));
    }
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    }
    if (data.containsKey('class_division_id')) {
      context.handle(
          _classDivisionIdMeta,
          classDivisionId.isAcceptableOrUnknown(
              data['class_division_id']!, _classDivisionIdMeta));
    }
    if (data.containsKey('count_per_week')) {
      context.handle(
          _countPerWeekMeta,
          countPerWeek.isAcceptableOrUnknown(
              data['count_per_week']!, _countPerWeekMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('fixed_day')) {
      context.handle(_fixedDayMeta,
          fixedDay.isAcceptableOrUnknown(data['fixed_day']!, _fixedDayMeta));
    }
    if (data.containsKey('fixed_period')) {
      context.handle(
          _fixedPeriodMeta,
          fixedPeriod.isAcceptableOrUnknown(
              data['fixed_period']!, _fixedPeriodMeta));
    }
    if (data.containsKey('room_type_id')) {
      context.handle(
          _roomTypeIdMeta,
          roomTypeId.isAcceptableOrUnknown(
              data['room_type_id']!, _roomTypeIdMeta));
    }
    if (data.containsKey('relationship_type')) {
      context.handle(
          _relationshipTypeMeta,
          relationshipType.isAcceptableOrUnknown(
              data['relationship_type']!, _relationshipTypeMeta));
    }
    if (data.containsKey('relationship_group_key')) {
      context.handle(
          _relationshipGroupKeyMeta,
          relationshipGroupKey.isAcceptableOrUnknown(
              data['relationship_group_key']!, _relationshipGroupKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
      periodsPerWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}periods_per_week'])!,
      teacherIds: $LessonsTable.$converterteacherIds.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}teacher_ids'])!),
      classIds: $LessonsTable.$converterclassIds.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_ids'])!),
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_id']),
      classDivisionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}class_division_id']),
      countPerWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}count_per_week'])!,
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      fixedDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fixed_day']),
      fixedPeriod: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fixed_period']),
      roomTypeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}room_type_id']),
      relationshipType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}relationship_type'])!,
      relationshipGroupKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}relationship_group_key']),
    );
  }

  @override
  $LessonsTable createAlias(String alias) {
    return $LessonsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterteacherIds =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterclassIds =
      const StringListConverter();
}

class LessonRow extends DataClass implements Insertable<LessonRow> {
  final String id;
  final String subjectId;
  final int periodsPerWeek;
  final List<String> teacherIds;
  final List<String> classIds;
  final String? classId;
  final String? classDivisionId;
  final int countPerWeek;
  final bool isPinned;
  final int? fixedDay;
  final int? fixedPeriod;
  final int? roomTypeId;
  final int relationshipType;
  final String? relationshipGroupKey;
  const LessonRow(
      {required this.id,
      required this.subjectId,
      required this.periodsPerWeek,
      required this.teacherIds,
      required this.classIds,
      this.classId,
      this.classDivisionId,
      required this.countPerWeek,
      required this.isPinned,
      this.fixedDay,
      this.fixedPeriod,
      this.roomTypeId,
      required this.relationshipType,
      this.relationshipGroupKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject_id'] = Variable<String>(subjectId);
    map['periods_per_week'] = Variable<int>(periodsPerWeek);
    {
      map['teacher_ids'] = Variable<String>(
          $LessonsTable.$converterteacherIds.toSql(teacherIds));
    }
    {
      map['class_ids'] =
          Variable<String>($LessonsTable.$converterclassIds.toSql(classIds));
    }
    if (!nullToAbsent || classId != null) {
      map['class_id'] = Variable<String>(classId);
    }
    if (!nullToAbsent || classDivisionId != null) {
      map['class_division_id'] = Variable<String>(classDivisionId);
    }
    map['count_per_week'] = Variable<int>(countPerWeek);
    map['is_pinned'] = Variable<bool>(isPinned);
    if (!nullToAbsent || fixedDay != null) {
      map['fixed_day'] = Variable<int>(fixedDay);
    }
    if (!nullToAbsent || fixedPeriod != null) {
      map['fixed_period'] = Variable<int>(fixedPeriod);
    }
    if (!nullToAbsent || roomTypeId != null) {
      map['room_type_id'] = Variable<int>(roomTypeId);
    }
    map['relationship_type'] = Variable<int>(relationshipType);
    if (!nullToAbsent || relationshipGroupKey != null) {
      map['relationship_group_key'] = Variable<String>(relationshipGroupKey);
    }
    return map;
  }

  LessonsCompanion toCompanion(bool nullToAbsent) {
    return LessonsCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      periodsPerWeek: Value(periodsPerWeek),
      teacherIds: Value(teacherIds),
      classIds: Value(classIds),
      classId: classId == null && nullToAbsent
          ? const Value.absent()
          : Value(classId),
      classDivisionId: classDivisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(classDivisionId),
      countPerWeek: Value(countPerWeek),
      isPinned: Value(isPinned),
      fixedDay: fixedDay == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedDay),
      fixedPeriod: fixedPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedPeriod),
      roomTypeId: roomTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(roomTypeId),
      relationshipType: Value(relationshipType),
      relationshipGroupKey: relationshipGroupKey == null && nullToAbsent
          ? const Value.absent()
          : Value(relationshipGroupKey),
    );
  }

  factory LessonRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonRow(
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      periodsPerWeek: serializer.fromJson<int>(json['periodsPerWeek']),
      teacherIds: serializer.fromJson<List<String>>(json['teacherIds']),
      classIds: serializer.fromJson<List<String>>(json['classIds']),
      classId: serializer.fromJson<String?>(json['classId']),
      classDivisionId: serializer.fromJson<String?>(json['classDivisionId']),
      countPerWeek: serializer.fromJson<int>(json['countPerWeek']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      fixedDay: serializer.fromJson<int?>(json['fixedDay']),
      fixedPeriod: serializer.fromJson<int?>(json['fixedPeriod']),
      roomTypeId: serializer.fromJson<int?>(json['roomTypeId']),
      relationshipType: serializer.fromJson<int>(json['relationshipType']),
      relationshipGroupKey:
          serializer.fromJson<String?>(json['relationshipGroupKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subjectId': serializer.toJson<String>(subjectId),
      'periodsPerWeek': serializer.toJson<int>(periodsPerWeek),
      'teacherIds': serializer.toJson<List<String>>(teacherIds),
      'classIds': serializer.toJson<List<String>>(classIds),
      'classId': serializer.toJson<String?>(classId),
      'classDivisionId': serializer.toJson<String?>(classDivisionId),
      'countPerWeek': serializer.toJson<int>(countPerWeek),
      'isPinned': serializer.toJson<bool>(isPinned),
      'fixedDay': serializer.toJson<int?>(fixedDay),
      'fixedPeriod': serializer.toJson<int?>(fixedPeriod),
      'roomTypeId': serializer.toJson<int?>(roomTypeId),
      'relationshipType': serializer.toJson<int>(relationshipType),
      'relationshipGroupKey': serializer.toJson<String?>(relationshipGroupKey),
    };
  }

  LessonRow copyWith(
          {String? id,
          String? subjectId,
          int? periodsPerWeek,
          List<String>? teacherIds,
          List<String>? classIds,
          Value<String?> classId = const Value.absent(),
          Value<String?> classDivisionId = const Value.absent(),
          int? countPerWeek,
          bool? isPinned,
          Value<int?> fixedDay = const Value.absent(),
          Value<int?> fixedPeriod = const Value.absent(),
          Value<int?> roomTypeId = const Value.absent(),
          int? relationshipType,
          Value<String?> relationshipGroupKey = const Value.absent()}) =>
      LessonRow(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
        periodsPerWeek: periodsPerWeek ?? this.periodsPerWeek,
        teacherIds: teacherIds ?? this.teacherIds,
        classIds: classIds ?? this.classIds,
        classId: classId.present ? classId.value : this.classId,
        classDivisionId: classDivisionId.present
            ? classDivisionId.value
            : this.classDivisionId,
        countPerWeek: countPerWeek ?? this.countPerWeek,
        isPinned: isPinned ?? this.isPinned,
        fixedDay: fixedDay.present ? fixedDay.value : this.fixedDay,
        fixedPeriod: fixedPeriod.present ? fixedPeriod.value : this.fixedPeriod,
        roomTypeId: roomTypeId.present ? roomTypeId.value : this.roomTypeId,
        relationshipType: relationshipType ?? this.relationshipType,
        relationshipGroupKey: relationshipGroupKey.present
            ? relationshipGroupKey.value
            : this.relationshipGroupKey,
      );
  LessonRow copyWithCompanion(LessonsCompanion data) {
    return LessonRow(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      periodsPerWeek: data.periodsPerWeek.present
          ? data.periodsPerWeek.value
          : this.periodsPerWeek,
      teacherIds:
          data.teacherIds.present ? data.teacherIds.value : this.teacherIds,
      classIds: data.classIds.present ? data.classIds.value : this.classIds,
      classId: data.classId.present ? data.classId.value : this.classId,
      classDivisionId: data.classDivisionId.present
          ? data.classDivisionId.value
          : this.classDivisionId,
      countPerWeek: data.countPerWeek.present
          ? data.countPerWeek.value
          : this.countPerWeek,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      fixedDay: data.fixedDay.present ? data.fixedDay.value : this.fixedDay,
      fixedPeriod:
          data.fixedPeriod.present ? data.fixedPeriod.value : this.fixedPeriod,
      roomTypeId:
          data.roomTypeId.present ? data.roomTypeId.value : this.roomTypeId,
      relationshipType: data.relationshipType.present
          ? data.relationshipType.value
          : this.relationshipType,
      relationshipGroupKey: data.relationshipGroupKey.present
          ? data.relationshipGroupKey.value
          : this.relationshipGroupKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonRow(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('periodsPerWeek: $periodsPerWeek, ')
          ..write('teacherIds: $teacherIds, ')
          ..write('classIds: $classIds, ')
          ..write('classId: $classId, ')
          ..write('classDivisionId: $classDivisionId, ')
          ..write('countPerWeek: $countPerWeek, ')
          ..write('isPinned: $isPinned, ')
          ..write('fixedDay: $fixedDay, ')
          ..write('fixedPeriod: $fixedPeriod, ')
          ..write('roomTypeId: $roomTypeId, ')
          ..write('relationshipType: $relationshipType, ')
          ..write('relationshipGroupKey: $relationshipGroupKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      subjectId,
      periodsPerWeek,
      teacherIds,
      classIds,
      classId,
      classDivisionId,
      countPerWeek,
      isPinned,
      fixedDay,
      fixedPeriod,
      roomTypeId,
      relationshipType,
      relationshipGroupKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonRow &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.periodsPerWeek == this.periodsPerWeek &&
          other.teacherIds == this.teacherIds &&
          other.classIds == this.classIds &&
          other.classId == this.classId &&
          other.classDivisionId == this.classDivisionId &&
          other.countPerWeek == this.countPerWeek &&
          other.isPinned == this.isPinned &&
          other.fixedDay == this.fixedDay &&
          other.fixedPeriod == this.fixedPeriod &&
          other.roomTypeId == this.roomTypeId &&
          other.relationshipType == this.relationshipType &&
          other.relationshipGroupKey == this.relationshipGroupKey);
}

class LessonsCompanion extends UpdateCompanion<LessonRow> {
  final Value<String> id;
  final Value<String> subjectId;
  final Value<int> periodsPerWeek;
  final Value<List<String>> teacherIds;
  final Value<List<String>> classIds;
  final Value<String?> classId;
  final Value<String?> classDivisionId;
  final Value<int> countPerWeek;
  final Value<bool> isPinned;
  final Value<int?> fixedDay;
  final Value<int?> fixedPeriod;
  final Value<int?> roomTypeId;
  final Value<int> relationshipType;
  final Value<String?> relationshipGroupKey;
  final Value<int> rowid;
  const LessonsCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.periodsPerWeek = const Value.absent(),
    this.teacherIds = const Value.absent(),
    this.classIds = const Value.absent(),
    this.classId = const Value.absent(),
    this.classDivisionId = const Value.absent(),
    this.countPerWeek = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.fixedDay = const Value.absent(),
    this.fixedPeriod = const Value.absent(),
    this.roomTypeId = const Value.absent(),
    this.relationshipType = const Value.absent(),
    this.relationshipGroupKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonsCompanion.insert({
    required String id,
    required String subjectId,
    this.periodsPerWeek = const Value.absent(),
    this.teacherIds = const Value.absent(),
    this.classIds = const Value.absent(),
    this.classId = const Value.absent(),
    this.classDivisionId = const Value.absent(),
    this.countPerWeek = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.fixedDay = const Value.absent(),
    this.fixedPeriod = const Value.absent(),
    this.roomTypeId = const Value.absent(),
    this.relationshipType = const Value.absent(),
    this.relationshipGroupKey = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        subjectId = Value(subjectId);
  static Insertable<LessonRow> custom({
    Expression<String>? id,
    Expression<String>? subjectId,
    Expression<int>? periodsPerWeek,
    Expression<String>? teacherIds,
    Expression<String>? classIds,
    Expression<String>? classId,
    Expression<String>? classDivisionId,
    Expression<int>? countPerWeek,
    Expression<bool>? isPinned,
    Expression<int>? fixedDay,
    Expression<int>? fixedPeriod,
    Expression<int>? roomTypeId,
    Expression<int>? relationshipType,
    Expression<String>? relationshipGroupKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (periodsPerWeek != null) 'periods_per_week': periodsPerWeek,
      if (teacherIds != null) 'teacher_ids': teacherIds,
      if (classIds != null) 'class_ids': classIds,
      if (classId != null) 'class_id': classId,
      if (classDivisionId != null) 'class_division_id': classDivisionId,
      if (countPerWeek != null) 'count_per_week': countPerWeek,
      if (isPinned != null) 'is_pinned': isPinned,
      if (fixedDay != null) 'fixed_day': fixedDay,
      if (fixedPeriod != null) 'fixed_period': fixedPeriod,
      if (roomTypeId != null) 'room_type_id': roomTypeId,
      if (relationshipType != null) 'relationship_type': relationshipType,
      if (relationshipGroupKey != null)
        'relationship_group_key': relationshipGroupKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonsCompanion copyWith(
      {Value<String>? id,
      Value<String>? subjectId,
      Value<int>? periodsPerWeek,
      Value<List<String>>? teacherIds,
      Value<List<String>>? classIds,
      Value<String?>? classId,
      Value<String?>? classDivisionId,
      Value<int>? countPerWeek,
      Value<bool>? isPinned,
      Value<int?>? fixedDay,
      Value<int?>? fixedPeriod,
      Value<int?>? roomTypeId,
      Value<int>? relationshipType,
      Value<String?>? relationshipGroupKey,
      Value<int>? rowid}) {
    return LessonsCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      periodsPerWeek: periodsPerWeek ?? this.periodsPerWeek,
      teacherIds: teacherIds ?? this.teacherIds,
      classIds: classIds ?? this.classIds,
      classId: classId ?? this.classId,
      classDivisionId: classDivisionId ?? this.classDivisionId,
      countPerWeek: countPerWeek ?? this.countPerWeek,
      isPinned: isPinned ?? this.isPinned,
      fixedDay: fixedDay ?? this.fixedDay,
      fixedPeriod: fixedPeriod ?? this.fixedPeriod,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      relationshipType: relationshipType ?? this.relationshipType,
      relationshipGroupKey: relationshipGroupKey ?? this.relationshipGroupKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (periodsPerWeek.present) {
      map['periods_per_week'] = Variable<int>(periodsPerWeek.value);
    }
    if (teacherIds.present) {
      map['teacher_ids'] = Variable<String>(
          $LessonsTable.$converterteacherIds.toSql(teacherIds.value));
    }
    if (classIds.present) {
      map['class_ids'] = Variable<String>(
          $LessonsTable.$converterclassIds.toSql(classIds.value));
    }
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (classDivisionId.present) {
      map['class_division_id'] = Variable<String>(classDivisionId.value);
    }
    if (countPerWeek.present) {
      map['count_per_week'] = Variable<int>(countPerWeek.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (fixedDay.present) {
      map['fixed_day'] = Variable<int>(fixedDay.value);
    }
    if (fixedPeriod.present) {
      map['fixed_period'] = Variable<int>(fixedPeriod.value);
    }
    if (roomTypeId.present) {
      map['room_type_id'] = Variable<int>(roomTypeId.value);
    }
    if (relationshipType.present) {
      map['relationship_type'] = Variable<int>(relationshipType.value);
    }
    if (relationshipGroupKey.present) {
      map['relationship_group_key'] =
          Variable<String>(relationshipGroupKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonsCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('periodsPerWeek: $periodsPerWeek, ')
          ..write('teacherIds: $teacherIds, ')
          ..write('classIds: $classIds, ')
          ..write('classId: $classId, ')
          ..write('classDivisionId: $classDivisionId, ')
          ..write('countPerWeek: $countPerWeek, ')
          ..write('isPinned: $isPinned, ')
          ..write('fixedDay: $fixedDay, ')
          ..write('fixedPeriod: $fixedPeriod, ')
          ..write('roomTypeId: $roomTypeId, ')
          ..write('relationshipType: $relationshipType, ')
          ..write('relationshipGroupKey: $relationshipGroupKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, CardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES lessons (id)'));
  static const VerificationMeta _dayIndexMeta =
      const VerificationMeta('dayIndex');
  @override
  late final GeneratedColumn<int> dayIndex = GeneratedColumn<int>(
      'day_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _periodIndexMeta =
      const VerificationMeta('periodIndex');
  @override
  late final GeneratedColumn<int> periodIndex = GeneratedColumn<int>(
      'period_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
      'room_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, lessonId, dayIndex, periodIndex, roomId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(Insertable<CardRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('day_index')) {
      context.handle(_dayIndexMeta,
          dayIndex.isAcceptableOrUnknown(data['day_index']!, _dayIndexMeta));
    } else if (isInserting) {
      context.missing(_dayIndexMeta);
    }
    if (data.containsKey('period_index')) {
      context.handle(
          _periodIndexMeta,
          periodIndex.isAcceptableOrUnknown(
              data['period_index']!, _periodIndexMeta));
    } else if (isInserting) {
      context.missing(_periodIndexMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      dayIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_index'])!,
      periodIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period_index'])!,
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room_id']),
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class CardRow extends DataClass implements Insertable<CardRow> {
  final String id;
  final String lessonId;
  final int dayIndex;
  final int periodIndex;
  final String? roomId;
  const CardRow(
      {required this.id,
      required this.lessonId,
      required this.dayIndex,
      required this.periodIndex,
      this.roomId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lesson_id'] = Variable<String>(lessonId);
    map['day_index'] = Variable<int>(dayIndex);
    map['period_index'] = Variable<int>(periodIndex);
    if (!nullToAbsent || roomId != null) {
      map['room_id'] = Variable<String>(roomId);
    }
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      lessonId: Value(lessonId),
      dayIndex: Value(dayIndex),
      periodIndex: Value(periodIndex),
      roomId:
          roomId == null && nullToAbsent ? const Value.absent() : Value(roomId),
    );
  }

  factory CardRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardRow(
      id: serializer.fromJson<String>(json['id']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      dayIndex: serializer.fromJson<int>(json['dayIndex']),
      periodIndex: serializer.fromJson<int>(json['periodIndex']),
      roomId: serializer.fromJson<String?>(json['roomId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lessonId': serializer.toJson<String>(lessonId),
      'dayIndex': serializer.toJson<int>(dayIndex),
      'periodIndex': serializer.toJson<int>(periodIndex),
      'roomId': serializer.toJson<String?>(roomId),
    };
  }

  CardRow copyWith(
          {String? id,
          String? lessonId,
          int? dayIndex,
          int? periodIndex,
          Value<String?> roomId = const Value.absent()}) =>
      CardRow(
        id: id ?? this.id,
        lessonId: lessonId ?? this.lessonId,
        dayIndex: dayIndex ?? this.dayIndex,
        periodIndex: periodIndex ?? this.periodIndex,
        roomId: roomId.present ? roomId.value : this.roomId,
      );
  CardRow copyWithCompanion(CardsCompanion data) {
    return CardRow(
      id: data.id.present ? data.id.value : this.id,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      dayIndex: data.dayIndex.present ? data.dayIndex.value : this.dayIndex,
      periodIndex:
          data.periodIndex.present ? data.periodIndex.value : this.periodIndex,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardRow(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('periodIndex: $periodIndex, ')
          ..write('roomId: $roomId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lessonId, dayIndex, periodIndex, roomId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardRow &&
          other.id == this.id &&
          other.lessonId == this.lessonId &&
          other.dayIndex == this.dayIndex &&
          other.periodIndex == this.periodIndex &&
          other.roomId == this.roomId);
}

class CardsCompanion extends UpdateCompanion<CardRow> {
  final Value<String> id;
  final Value<String> lessonId;
  final Value<int> dayIndex;
  final Value<int> periodIndex;
  final Value<String?> roomId;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.dayIndex = const Value.absent(),
    this.periodIndex = const Value.absent(),
    this.roomId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String lessonId,
    required int dayIndex,
    required int periodIndex,
    this.roomId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        lessonId = Value(lessonId),
        dayIndex = Value(dayIndex),
        periodIndex = Value(periodIndex);
  static Insertable<CardRow> custom({
    Expression<String>? id,
    Expression<String>? lessonId,
    Expression<int>? dayIndex,
    Expression<int>? periodIndex,
    Expression<String>? roomId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      if (dayIndex != null) 'day_index': dayIndex,
      if (periodIndex != null) 'period_index': periodIndex,
      if (roomId != null) 'room_id': roomId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith(
      {Value<String>? id,
      Value<String>? lessonId,
      Value<int>? dayIndex,
      Value<int>? periodIndex,
      Value<String?>? roomId,
      Value<int>? rowid}) {
    return CardsCompanion(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      dayIndex: dayIndex ?? this.dayIndex,
      periodIndex: periodIndex ?? this.periodIndex,
      roomId: roomId ?? this.roomId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (dayIndex.present) {
      map['day_index'] = Variable<int>(dayIndex.value);
    }
    if (periodIndex.present) {
      map['period_index'] = Variable<int>(periodIndex.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('periodIndex: $periodIndex, ')
          ..write('roomId: $roomId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonClassesTable extends LessonClasses
    with TableInfo<$LessonClassesTable, LessonClassesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonClassesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES lessons (id)'));
  static const VerificationMeta _classIdMeta =
      const VerificationMeta('classId');
  @override
  late final GeneratedColumn<String> classId = GeneratedColumn<String>(
      'class_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES classes (id)'));
  @override
  List<GeneratedColumn> get $columns => [lessonId, classId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_classes';
  @override
  VerificationContext validateIntegrity(Insertable<LessonClassesData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId, classId};
  @override
  LessonClassesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonClassesData(
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_id'])!,
    );
  }

  @override
  $LessonClassesTable createAlias(String alias) {
    return $LessonClassesTable(attachedDatabase, alias);
  }
}

class LessonClassesData extends DataClass
    implements Insertable<LessonClassesData> {
  final String lessonId;
  final String classId;
  const LessonClassesData({required this.lessonId, required this.classId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['class_id'] = Variable<String>(classId);
    return map;
  }

  LessonClassesCompanion toCompanion(bool nullToAbsent) {
    return LessonClassesCompanion(
      lessonId: Value(lessonId),
      classId: Value(classId),
    );
  }

  factory LessonClassesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonClassesData(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      classId: serializer.fromJson<String>(json['classId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'classId': serializer.toJson<String>(classId),
    };
  }

  LessonClassesData copyWith({String? lessonId, String? classId}) =>
      LessonClassesData(
        lessonId: lessonId ?? this.lessonId,
        classId: classId ?? this.classId,
      );
  LessonClassesData copyWithCompanion(LessonClassesCompanion data) {
    return LessonClassesData(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      classId: data.classId.present ? data.classId.value : this.classId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonClassesData(')
          ..write('lessonId: $lessonId, ')
          ..write('classId: $classId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lessonId, classId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonClassesData &&
          other.lessonId == this.lessonId &&
          other.classId == this.classId);
}

class LessonClassesCompanion extends UpdateCompanion<LessonClassesData> {
  final Value<String> lessonId;
  final Value<String> classId;
  final Value<int> rowid;
  const LessonClassesCompanion({
    this.lessonId = const Value.absent(),
    this.classId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonClassesCompanion.insert({
    required String lessonId,
    required String classId,
    this.rowid = const Value.absent(),
  })  : lessonId = Value(lessonId),
        classId = Value(classId);
  static Insertable<LessonClassesData> custom({
    Expression<String>? lessonId,
    Expression<String>? classId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (classId != null) 'class_id': classId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonClassesCompanion copyWith(
      {Value<String>? lessonId, Value<String>? classId, Value<int>? rowid}) {
    return LessonClassesCompanion(
      lessonId: lessonId ?? this.lessonId,
      classId: classId ?? this.classId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonClassesCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('classId: $classId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonTeachersTable extends LessonTeachers
    with TableInfo<$LessonTeachersTable, LessonTeacher> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonTeachersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES lessons (id)'));
  static const VerificationMeta _teacherIdMeta =
      const VerificationMeta('teacherId');
  @override
  late final GeneratedColumn<String> teacherId = GeneratedColumn<String>(
      'teacher_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES teachers (id)'));
  @override
  List<GeneratedColumn> get $columns => [lessonId, teacherId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_teachers';
  @override
  VerificationContext validateIntegrity(Insertable<LessonTeacher> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('teacher_id')) {
      context.handle(_teacherIdMeta,
          teacherId.isAcceptableOrUnknown(data['teacher_id']!, _teacherIdMeta));
    } else if (isInserting) {
      context.missing(_teacherIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId, teacherId};
  @override
  LessonTeacher map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonTeacher(
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      teacherId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}teacher_id'])!,
    );
  }

  @override
  $LessonTeachersTable createAlias(String alias) {
    return $LessonTeachersTable(attachedDatabase, alias);
  }
}

class LessonTeacher extends DataClass implements Insertable<LessonTeacher> {
  final String lessonId;
  final String teacherId;
  const LessonTeacher({required this.lessonId, required this.teacherId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['teacher_id'] = Variable<String>(teacherId);
    return map;
  }

  LessonTeachersCompanion toCompanion(bool nullToAbsent) {
    return LessonTeachersCompanion(
      lessonId: Value(lessonId),
      teacherId: Value(teacherId),
    );
  }

  factory LessonTeacher.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonTeacher(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      teacherId: serializer.fromJson<String>(json['teacherId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'teacherId': serializer.toJson<String>(teacherId),
    };
  }

  LessonTeacher copyWith({String? lessonId, String? teacherId}) =>
      LessonTeacher(
        lessonId: lessonId ?? this.lessonId,
        teacherId: teacherId ?? this.teacherId,
      );
  LessonTeacher copyWithCompanion(LessonTeachersCompanion data) {
    return LessonTeacher(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      teacherId: data.teacherId.present ? data.teacherId.value : this.teacherId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonTeacher(')
          ..write('lessonId: $lessonId, ')
          ..write('teacherId: $teacherId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lessonId, teacherId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonTeacher &&
          other.lessonId == this.lessonId &&
          other.teacherId == this.teacherId);
}

class LessonTeachersCompanion extends UpdateCompanion<LessonTeacher> {
  final Value<String> lessonId;
  final Value<String> teacherId;
  final Value<int> rowid;
  const LessonTeachersCompanion({
    this.lessonId = const Value.absent(),
    this.teacherId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonTeachersCompanion.insert({
    required String lessonId,
    required String teacherId,
    this.rowid = const Value.absent(),
  })  : lessonId = Value(lessonId),
        teacherId = Value(teacherId);
  static Insertable<LessonTeacher> custom({
    Expression<String>? lessonId,
    Expression<String>? teacherId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (teacherId != null) 'teacher_id': teacherId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonTeachersCompanion copyWith(
      {Value<String>? lessonId, Value<String>? teacherId, Value<int>? rowid}) {
    return LessonTeachersCompanion(
      lessonId: lessonId ?? this.lessonId,
      teacherId: teacherId ?? this.teacherId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (teacherId.present) {
      map['teacher_id'] = Variable<String>(teacherId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonTeachersCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('teacherId: $teacherId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntityTimeOffTable extends EntityTimeOff
    with TableInfo<$EntityTimeOffTable, EntityTimeOffData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntityTimeOffTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
      'day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<int> period = GeneratedColumn<int>(
      'period', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
      'state', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, entityType, entityId, day, period, state];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entity_time_off';
  @override
  VerificationContext validateIntegrity(Insertable<EntityTimeOffData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('period')) {
      context.handle(_periodMeta,
          period.isAcceptableOrUnknown(data['period']!, _periodMeta));
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntityTimeOffData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntityTimeOffData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      period: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}state'])!,
    );
  }

  @override
  $EntityTimeOffTable createAlias(String alias) {
    return $EntityTimeOffTable(attachedDatabase, alias);
  }
}

class EntityTimeOffData extends DataClass
    implements Insertable<EntityTimeOffData> {
  final String id;
  final String entityType;
  final String entityId;
  final int day;
  final int period;
  final int state;
  const EntityTimeOffData(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.day,
      required this.period,
      required this.state});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['day'] = Variable<int>(day);
    map['period'] = Variable<int>(period);
    map['state'] = Variable<int>(state);
    return map;
  }

  EntityTimeOffCompanion toCompanion(bool nullToAbsent) {
    return EntityTimeOffCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      day: Value(day),
      period: Value(period),
      state: Value(state),
    );
  }

  factory EntityTimeOffData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntityTimeOffData(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      day: serializer.fromJson<int>(json['day']),
      period: serializer.fromJson<int>(json['period']),
      state: serializer.fromJson<int>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'day': serializer.toJson<int>(day),
      'period': serializer.toJson<int>(period),
      'state': serializer.toJson<int>(state),
    };
  }

  EntityTimeOffData copyWith(
          {String? id,
          String? entityType,
          String? entityId,
          int? day,
          int? period,
          int? state}) =>
      EntityTimeOffData(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        day: day ?? this.day,
        period: period ?? this.period,
        state: state ?? this.state,
      );
  EntityTimeOffData copyWithCompanion(EntityTimeOffCompanion data) {
    return EntityTimeOffData(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      day: data.day.present ? data.day.value : this.day,
      period: data.period.present ? data.period.value : this.period,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntityTimeOffData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('day: $day, ')
          ..write('period: $period, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityType, entityId, day, period, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntityTimeOffData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.day == this.day &&
          other.period == this.period &&
          other.state == this.state);
}

class EntityTimeOffCompanion extends UpdateCompanion<EntityTimeOffData> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<int> day;
  final Value<int> period;
  final Value<int> state;
  final Value<int> rowid;
  const EntityTimeOffCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.day = const Value.absent(),
    this.period = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntityTimeOffCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required int day,
    required int period,
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        entityType = Value(entityType),
        entityId = Value(entityId),
        day = Value(day),
        period = Value(period);
  static Insertable<EntityTimeOffData> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<int>? day,
    Expression<int>? period,
    Expression<int>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (day != null) 'day': day,
      if (period != null) 'period': period,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntityTimeOffCompanion copyWith(
      {Value<String>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<int>? day,
      Value<int>? period,
      Value<int>? state,
      Value<int>? rowid}) {
    return EntityTimeOffCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      day: day ?? this.day,
      period: period ?? this.period,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (period.present) {
      map['period'] = Variable<int>(period.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntityTimeOffCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('day: $day, ')
          ..write('period: $period, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SoftConstraintProfilesTable extends SoftConstraintProfiles
    with TableInfo<$SoftConstraintProfilesTable, SoftConstraintProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SoftConstraintProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _maxGapsPerDayMeta =
      const VerificationMeta('maxGapsPerDay');
  @override
  late final GeneratedColumn<int> maxGapsPerDay = GeneratedColumn<int>(
      'max_gaps_per_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxConsecutivePeriodsMeta =
      const VerificationMeta('maxConsecutivePeriods');
  @override
  late final GeneratedColumn<int> maxConsecutivePeriods = GeneratedColumn<int>(
      'max_consecutive_periods', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, entityType, entityId, maxGapsPerDay, maxConsecutivePeriods];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'soft_constraint_profiles';
  @override
  VerificationContext validateIntegrity(
      Insertable<SoftConstraintProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('max_gaps_per_day')) {
      context.handle(
          _maxGapsPerDayMeta,
          maxGapsPerDay.isAcceptableOrUnknown(
              data['max_gaps_per_day']!, _maxGapsPerDayMeta));
    }
    if (data.containsKey('max_consecutive_periods')) {
      context.handle(
          _maxConsecutivePeriodsMeta,
          maxConsecutivePeriods.isAcceptableOrUnknown(
              data['max_consecutive_periods']!, _maxConsecutivePeriodsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SoftConstraintProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SoftConstraintProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      maxGapsPerDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_gaps_per_day']),
      maxConsecutivePeriods: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}max_consecutive_periods']),
    );
  }

  @override
  $SoftConstraintProfilesTable createAlias(String alias) {
    return $SoftConstraintProfilesTable(attachedDatabase, alias);
  }
}

class SoftConstraintProfile extends DataClass
    implements Insertable<SoftConstraintProfile> {
  final String id;
  final String entityType;
  final String entityId;
  final int? maxGapsPerDay;
  final int? maxConsecutivePeriods;
  const SoftConstraintProfile(
      {required this.id,
      required this.entityType,
      required this.entityId,
      this.maxGapsPerDay,
      this.maxConsecutivePeriods});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || maxGapsPerDay != null) {
      map['max_gaps_per_day'] = Variable<int>(maxGapsPerDay);
    }
    if (!nullToAbsent || maxConsecutivePeriods != null) {
      map['max_consecutive_periods'] = Variable<int>(maxConsecutivePeriods);
    }
    return map;
  }

  SoftConstraintProfilesCompanion toCompanion(bool nullToAbsent) {
    return SoftConstraintProfilesCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      maxGapsPerDay: maxGapsPerDay == null && nullToAbsent
          ? const Value.absent()
          : Value(maxGapsPerDay),
      maxConsecutivePeriods: maxConsecutivePeriods == null && nullToAbsent
          ? const Value.absent()
          : Value(maxConsecutivePeriods),
    );
  }

  factory SoftConstraintProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SoftConstraintProfile(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      maxGapsPerDay: serializer.fromJson<int?>(json['maxGapsPerDay']),
      maxConsecutivePeriods:
          serializer.fromJson<int?>(json['maxConsecutivePeriods']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'maxGapsPerDay': serializer.toJson<int?>(maxGapsPerDay),
      'maxConsecutivePeriods': serializer.toJson<int?>(maxConsecutivePeriods),
    };
  }

  SoftConstraintProfile copyWith(
          {String? id,
          String? entityType,
          String? entityId,
          Value<int?> maxGapsPerDay = const Value.absent(),
          Value<int?> maxConsecutivePeriods = const Value.absent()}) =>
      SoftConstraintProfile(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        maxGapsPerDay:
            maxGapsPerDay.present ? maxGapsPerDay.value : this.maxGapsPerDay,
        maxConsecutivePeriods: maxConsecutivePeriods.present
            ? maxConsecutivePeriods.value
            : this.maxConsecutivePeriods,
      );
  SoftConstraintProfile copyWithCompanion(
      SoftConstraintProfilesCompanion data) {
    return SoftConstraintProfile(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      maxGapsPerDay: data.maxGapsPerDay.present
          ? data.maxGapsPerDay.value
          : this.maxGapsPerDay,
      maxConsecutivePeriods: data.maxConsecutivePeriods.present
          ? data.maxConsecutivePeriods.value
          : this.maxConsecutivePeriods,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SoftConstraintProfile(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('maxGapsPerDay: $maxGapsPerDay, ')
          ..write('maxConsecutivePeriods: $maxConsecutivePeriods')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, entityType, entityId, maxGapsPerDay, maxConsecutivePeriods);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SoftConstraintProfile &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.maxGapsPerDay == this.maxGapsPerDay &&
          other.maxConsecutivePeriods == this.maxConsecutivePeriods);
}

class SoftConstraintProfilesCompanion
    extends UpdateCompanion<SoftConstraintProfile> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<int?> maxGapsPerDay;
  final Value<int?> maxConsecutivePeriods;
  final Value<int> rowid;
  const SoftConstraintProfilesCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.maxGapsPerDay = const Value.absent(),
    this.maxConsecutivePeriods = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SoftConstraintProfilesCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    this.maxGapsPerDay = const Value.absent(),
    this.maxConsecutivePeriods = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        entityType = Value(entityType),
        entityId = Value(entityId);
  static Insertable<SoftConstraintProfile> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<int>? maxGapsPerDay,
    Expression<int>? maxConsecutivePeriods,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (maxGapsPerDay != null) 'max_gaps_per_day': maxGapsPerDay,
      if (maxConsecutivePeriods != null)
        'max_consecutive_periods': maxConsecutivePeriods,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SoftConstraintProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<int?>? maxGapsPerDay,
      Value<int?>? maxConsecutivePeriods,
      Value<int>? rowid}) {
    return SoftConstraintProfilesCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      maxGapsPerDay: maxGapsPerDay ?? this.maxGapsPerDay,
      maxConsecutivePeriods:
          maxConsecutivePeriods ?? this.maxConsecutivePeriods,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (maxGapsPerDay.present) {
      map['max_gaps_per_day'] = Variable<int>(maxGapsPerDay.value);
    }
    if (maxConsecutivePeriods.present) {
      map['max_consecutive_periods'] =
          Variable<int>(maxConsecutivePeriods.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SoftConstraintProfilesCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('maxGapsPerDay: $maxGapsPerDay, ')
          ..write('maxConsecutivePeriods: $maxConsecutivePeriods, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppStateTable extends AppState
    with TableInfo<$AppStateTable, AppStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _plannerJsonMeta =
      const VerificationMeta('plannerJson');
  @override
  late final GeneratedColumn<String> plannerJson = GeneratedColumn<String>(
      'planner_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, plannerJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_state';
  @override
  VerificationContext validateIntegrity(Insertable<AppStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('planner_json')) {
      context.handle(
          _plannerJsonMeta,
          plannerJson.isAcceptableOrUnknown(
              data['planner_json']!, _plannerJsonMeta));
    } else if (isInserting) {
      context.missing(_plannerJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppStateData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      plannerJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}planner_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppStateTable createAlias(String alias) {
    return $AppStateTable(attachedDatabase, alias);
  }
}

class AppStateData extends DataClass implements Insertable<AppStateData> {
  final int id;
  final String plannerJson;
  final DateTime updatedAt;
  const AppStateData(
      {required this.id, required this.plannerJson, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['planner_json'] = Variable<String>(plannerJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppStateCompanion toCompanion(bool nullToAbsent) {
    return AppStateCompanion(
      id: Value(id),
      plannerJson: Value(plannerJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppStateData(
      id: serializer.fromJson<int>(json['id']),
      plannerJson: serializer.fromJson<String>(json['plannerJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plannerJson': serializer.toJson<String>(plannerJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppStateData copyWith({int? id, String? plannerJson, DateTime? updatedAt}) =>
      AppStateData(
        id: id ?? this.id,
        plannerJson: plannerJson ?? this.plannerJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppStateData copyWithCompanion(AppStateCompanion data) {
    return AppStateData(
      id: data.id.present ? data.id.value : this.id,
      plannerJson:
          data.plannerJson.present ? data.plannerJson.value : this.plannerJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppStateData(')
          ..write('id: $id, ')
          ..write('plannerJson: $plannerJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, plannerJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppStateData &&
          other.id == this.id &&
          other.plannerJson == this.plannerJson &&
          other.updatedAt == this.updatedAt);
}

class AppStateCompanion extends UpdateCompanion<AppStateData> {
  final Value<int> id;
  final Value<String> plannerJson;
  final Value<DateTime> updatedAt;
  const AppStateCompanion({
    this.id = const Value.absent(),
    this.plannerJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppStateCompanion.insert({
    this.id = const Value.absent(),
    required String plannerJson,
    this.updatedAt = const Value.absent(),
  }) : plannerJson = Value(plannerJson);
  static Insertable<AppStateData> custom({
    Expression<int>? id,
    Expression<String>? plannerJson,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plannerJson != null) 'planner_json': plannerJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppStateCompanion copyWith(
      {Value<int>? id,
      Value<String>? plannerJson,
      Value<DateTime>? updatedAt}) {
    return AppStateCompanion(
      id: id ?? this.id,
      plannerJson: plannerJson ?? this.plannerJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plannerJson.present) {
      map['planner_json'] = Variable<String>(plannerJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppStateCompanion(')
          ..write('id: $id, ')
          ..write('plannerJson: $plannerJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $ClassesTable classes = $ClassesTable(this);
  late final $DivisionsTable divisions = $DivisionsTable(this);
  late final $TeachersTable teachers = $TeachersTable(this);
  late final $TeacherUnavailabilityTable teacherUnavailability =
      $TeacherUnavailabilityTable(this);
  late final $LessonsTable lessons = $LessonsTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $LessonClassesTable lessonClasses = $LessonClassesTable(this);
  late final $LessonTeachersTable lessonTeachers = $LessonTeachersTable(this);
  late final $EntityTimeOffTable entityTimeOff = $EntityTimeOffTable(this);
  late final $SoftConstraintProfilesTable softConstraintProfiles =
      $SoftConstraintProfilesTable(this);
  late final $AppStateTable appState = $AppStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        subjects,
        classes,
        divisions,
        teachers,
        teacherUnavailability,
        lessons,
        cards,
        lessonClasses,
        lessonTeachers,
        entityTimeOff,
        softConstraintProfiles,
        appState
      ];
}

typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  required String id,
  required String name,
  required String abbr,
  Value<String?> groupId,
  Value<int?> roomTypeId,
  Value<int> color,
  Value<int> rowid,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> abbr,
  Value<String?> groupId,
  Value<int?> roomTypeId,
  Value<int> color,
  Value<int> rowid,
});

final class $$SubjectsTableReferences
    extends BaseReferences<_$AppDatabase, $SubjectsTable, SubjectRow> {
  $$SubjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LessonsTable, List<LessonRow>> _lessonsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lessons,
          aliasName:
              $_aliasNameGenerator(db.subjects.id, db.lessons.subjectId));

  $$LessonsTableProcessedTableManager get lessonsRefs {
    final manager = $$LessonsTableTableManager($_db, $_db.lessons)
        .filter((f) => f.subjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get abbr => $composableBuilder(
      column: $table.abbr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get roomTypeId => $composableBuilder(
      column: $table.roomTypeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  Expression<bool> lessonsRefs(
      Expression<bool> Function($$LessonsTableFilterComposer f) f) {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableFilterComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get abbr => $composableBuilder(
      column: $table.abbr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get roomTypeId => $composableBuilder(
      column: $table.roomTypeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get abbr =>
      $composableBuilder(column: $table.abbr, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get roomTypeId => $composableBuilder(
      column: $table.roomTypeId, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  Expression<T> lessonsRefs<T extends Object>(
      Expression<T> Function($$LessonsTableAnnotationComposer a) f) {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.subjectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableAnnotationComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SubjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubjectsTable,
    SubjectRow,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (SubjectRow, $$SubjectsTableReferences),
    SubjectRow,
    PrefetchHooks Function({bool lessonsRefs})> {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> abbr = const Value.absent(),
            Value<String?> groupId = const Value.absent(),
            Value<int?> roomTypeId = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion(
            id: id,
            name: name,
            abbr: abbr,
            groupId: groupId,
            roomTypeId: roomTypeId,
            color: color,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String abbr,
            Value<String?> groupId = const Value.absent(),
            Value<int?> roomTypeId = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion.insert(
            id: id,
            name: name,
            abbr: abbr,
            groupId: groupId,
            roomTypeId: roomTypeId,
            color: color,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SubjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({lessonsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (lessonsRefs) db.lessons],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lessonsRefs)
                    await $_getPrefetchedData<SubjectRow, $SubjectsTable,
                            LessonRow>(
                        currentTable: table,
                        referencedTable:
                            $$SubjectsTableReferences._lessonsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SubjectsTableReferences(db, table, p0)
                                .lessonsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.subjectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SubjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubjectsTable,
    SubjectRow,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (SubjectRow, $$SubjectsTableReferences),
    SubjectRow,
    PrefetchHooks Function({bool lessonsRefs})>;
typedef $$ClassesTableCreateCompanionBuilder = ClassesCompanion Function({
  required String id,
  required String name,
  required String abbr,
  Value<int> rowid,
});
typedef $$ClassesTableUpdateCompanionBuilder = ClassesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> abbr,
  Value<int> rowid,
});

final class $$ClassesTableReferences
    extends BaseReferences<_$AppDatabase, $ClassesTable, ClassRow> {
  $$ClassesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DivisionsTable, List<DivisionRow>>
      _divisionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.divisions,
          aliasName: $_aliasNameGenerator(db.classes.id, db.divisions.classId));

  $$DivisionsTableProcessedTableManager get divisionsRefs {
    final manager = $$DivisionsTableTableManager($_db, $_db.divisions)
        .filter((f) => f.classId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_divisionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LessonClassesTable, List<LessonClassesData>>
      _lessonClassesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.lessonClasses,
              aliasName: $_aliasNameGenerator(
                  db.classes.id, db.lessonClasses.classId));

  $$LessonClassesTableProcessedTableManager get lessonClassesRefs {
    final manager = $$LessonClassesTableTableManager($_db, $_db.lessonClasses)
        .filter((f) => f.classId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonClassesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ClassesTableFilterComposer
    extends Composer<_$AppDatabase, $ClassesTable> {
  $$ClassesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get abbr => $composableBuilder(
      column: $table.abbr, builder: (column) => ColumnFilters(column));

  Expression<bool> divisionsRefs(
      Expression<bool> Function($$DivisionsTableFilterComposer f) f) {
    final $$DivisionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.divisions,
        getReferencedColumn: (t) => t.classId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DivisionsTableFilterComposer(
              $db: $db,
              $table: $db.divisions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> lessonClassesRefs(
      Expression<bool> Function($$LessonClassesTableFilterComposer f) f) {
    final $$LessonClassesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessonClasses,
        getReferencedColumn: (t) => t.classId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonClassesTableFilterComposer(
              $db: $db,
              $table: $db.lessonClasses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ClassesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassesTable> {
  $$ClassesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get abbr => $composableBuilder(
      column: $table.abbr, builder: (column) => ColumnOrderings(column));
}

class $$ClassesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassesTable> {
  $$ClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get abbr =>
      $composableBuilder(column: $table.abbr, builder: (column) => column);

  Expression<T> divisionsRefs<T extends Object>(
      Expression<T> Function($$DivisionsTableAnnotationComposer a) f) {
    final $$DivisionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.divisions,
        getReferencedColumn: (t) => t.classId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DivisionsTableAnnotationComposer(
              $db: $db,
              $table: $db.divisions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> lessonClassesRefs<T extends Object>(
      Expression<T> Function($$LessonClassesTableAnnotationComposer a) f) {
    final $$LessonClassesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessonClasses,
        getReferencedColumn: (t) => t.classId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonClassesTableAnnotationComposer(
              $db: $db,
              $table: $db.lessonClasses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ClassesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClassesTable,
    ClassRow,
    $$ClassesTableFilterComposer,
    $$ClassesTableOrderingComposer,
    $$ClassesTableAnnotationComposer,
    $$ClassesTableCreateCompanionBuilder,
    $$ClassesTableUpdateCompanionBuilder,
    (ClassRow, $$ClassesTableReferences),
    ClassRow,
    PrefetchHooks Function({bool divisionsRefs, bool lessonClassesRefs})> {
  $$ClassesTableTableManager(_$AppDatabase db, $ClassesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> abbr = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClassesCompanion(
            id: id,
            name: name,
            abbr: abbr,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String abbr,
            Value<int> rowid = const Value.absent(),
          }) =>
              ClassesCompanion.insert(
            id: id,
            name: name,
            abbr: abbr,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ClassesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {divisionsRefs = false, lessonClassesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (divisionsRefs) db.divisions,
                if (lessonClassesRefs) db.lessonClasses
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (divisionsRefs)
                    await $_getPrefetchedData<ClassRow, $ClassesTable,
                            DivisionRow>(
                        currentTable: table,
                        referencedTable:
                            $$ClassesTableReferences._divisionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClassesTableReferences(db, table, p0)
                                .divisionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.classId == item.id),
                        typedResults: items),
                  if (lessonClassesRefs)
                    await $_getPrefetchedData<ClassRow, $ClassesTable,
                            LessonClassesData>(
                        currentTable: table,
                        referencedTable: $$ClassesTableReferences
                            ._lessonClassesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClassesTableReferences(db, table, p0)
                                .lessonClassesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.classId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ClassesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClassesTable,
    ClassRow,
    $$ClassesTableFilterComposer,
    $$ClassesTableOrderingComposer,
    $$ClassesTableAnnotationComposer,
    $$ClassesTableCreateCompanionBuilder,
    $$ClassesTableUpdateCompanionBuilder,
    (ClassRow, $$ClassesTableReferences),
    ClassRow,
    PrefetchHooks Function({bool divisionsRefs, bool lessonClassesRefs})>;
typedef $$DivisionsTableCreateCompanionBuilder = DivisionsCompanion Function({
  required String id,
  required String name,
  required String classId,
  Value<int> rowid,
});
typedef $$DivisionsTableUpdateCompanionBuilder = DivisionsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> classId,
  Value<int> rowid,
});

final class $$DivisionsTableReferences
    extends BaseReferences<_$AppDatabase, $DivisionsTable, DivisionRow> {
  $$DivisionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClassesTable _classIdTable(_$AppDatabase db) => db.classes
      .createAlias($_aliasNameGenerator(db.divisions.classId, db.classes.id));

  $$ClassesTableProcessedTableManager get classId {
    final $_column = $_itemColumn<String>('class_id')!;

    final manager = $$ClassesTableTableManager($_db, $_db.classes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$LessonsTable, List<LessonRow>> _lessonsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lessons,
          aliasName: $_aliasNameGenerator(
              db.divisions.id, db.lessons.classDivisionId));

  $$LessonsTableProcessedTableManager get lessonsRefs {
    final manager = $$LessonsTableTableManager($_db, $_db.lessons).filter(
        (f) => f.classDivisionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DivisionsTableFilterComposer
    extends Composer<_$AppDatabase, $DivisionsTable> {
  $$DivisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  $$ClassesTableFilterComposer get classId {
    final $$ClassesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classId,
        referencedTable: $db.classes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassesTableFilterComposer(
              $db: $db,
              $table: $db.classes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> lessonsRefs(
      Expression<bool> Function($$LessonsTableFilterComposer f) f) {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.classDivisionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableFilterComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DivisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DivisionsTable> {
  $$DivisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  $$ClassesTableOrderingComposer get classId {
    final $$ClassesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classId,
        referencedTable: $db.classes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassesTableOrderingComposer(
              $db: $db,
              $table: $db.classes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DivisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DivisionsTable> {
  $$DivisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$ClassesTableAnnotationComposer get classId {
    final $$ClassesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classId,
        referencedTable: $db.classes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassesTableAnnotationComposer(
              $db: $db,
              $table: $db.classes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> lessonsRefs<T extends Object>(
      Expression<T> Function($$LessonsTableAnnotationComposer a) f) {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.classDivisionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableAnnotationComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DivisionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DivisionsTable,
    DivisionRow,
    $$DivisionsTableFilterComposer,
    $$DivisionsTableOrderingComposer,
    $$DivisionsTableAnnotationComposer,
    $$DivisionsTableCreateCompanionBuilder,
    $$DivisionsTableUpdateCompanionBuilder,
    (DivisionRow, $$DivisionsTableReferences),
    DivisionRow,
    PrefetchHooks Function({bool classId, bool lessonsRefs})> {
  $$DivisionsTableTableManager(_$AppDatabase db, $DivisionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DivisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DivisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DivisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> classId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DivisionsCompanion(
            id: id,
            name: name,
            classId: classId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String classId,
            Value<int> rowid = const Value.absent(),
          }) =>
              DivisionsCompanion.insert(
            id: id,
            name: name,
            classId: classId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DivisionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({classId = false, lessonsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (lessonsRefs) db.lessons],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (classId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.classId,
                    referencedTable:
                        $$DivisionsTableReferences._classIdTable(db),
                    referencedColumn:
                        $$DivisionsTableReferences._classIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lessonsRefs)
                    await $_getPrefetchedData<DivisionRow, $DivisionsTable,
                            LessonRow>(
                        currentTable: table,
                        referencedTable:
                            $$DivisionsTableReferences._lessonsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DivisionsTableReferences(db, table, p0)
                                .lessonsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.classDivisionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DivisionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DivisionsTable,
    DivisionRow,
    $$DivisionsTableFilterComposer,
    $$DivisionsTableOrderingComposer,
    $$DivisionsTableAnnotationComposer,
    $$DivisionsTableCreateCompanionBuilder,
    $$DivisionsTableUpdateCompanionBuilder,
    (DivisionRow, $$DivisionsTableReferences),
    DivisionRow,
    PrefetchHooks Function({bool classId, bool lessonsRefs})>;
typedef $$TeachersTableCreateCompanionBuilder = TeachersCompanion Function({
  required String id,
  required String name,
  required String abbreviation,
  Value<int?> maxPeriodsPerDay,
  Value<int?> maxGapsPerDay,
  Value<int> rowid,
});
typedef $$TeachersTableUpdateCompanionBuilder = TeachersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> abbreviation,
  Value<int?> maxPeriodsPerDay,
  Value<int?> maxGapsPerDay,
  Value<int> rowid,
});

final class $$TeachersTableReferences
    extends BaseReferences<_$AppDatabase, $TeachersTable, TeacherRow> {
  $$TeachersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TeacherUnavailabilityTable,
      List<TeacherUnavailabilityRow>> _teacherUnavailabilityRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.teacherUnavailability,
          aliasName: $_aliasNameGenerator(
              db.teachers.id, db.teacherUnavailability.teacherId));

  $$TeacherUnavailabilityTableProcessedTableManager
      get teacherUnavailabilityRefs {
    final manager = $$TeacherUnavailabilityTableTableManager(
            $_db, $_db.teacherUnavailability)
        .filter((f) => f.teacherId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_teacherUnavailabilityRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LessonTeachersTable, List<LessonTeacher>>
      _lessonTeachersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.lessonTeachers,
              aliasName: $_aliasNameGenerator(
                  db.teachers.id, db.lessonTeachers.teacherId));

  $$LessonTeachersTableProcessedTableManager get lessonTeachersRefs {
    final manager = $$LessonTeachersTableTableManager($_db, $_db.lessonTeachers)
        .filter((f) => f.teacherId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonTeachersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TeachersTableFilterComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get abbreviation => $composableBuilder(
      column: $table.abbreviation, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxPeriodsPerDay => $composableBuilder(
      column: $table.maxPeriodsPerDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxGapsPerDay => $composableBuilder(
      column: $table.maxGapsPerDay, builder: (column) => ColumnFilters(column));

  Expression<bool> teacherUnavailabilityRefs(
      Expression<bool> Function($$TeacherUnavailabilityTableFilterComposer f)
          f) {
    final $$TeacherUnavailabilityTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.teacherUnavailability,
            getReferencedColumn: (t) => t.teacherId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TeacherUnavailabilityTableFilterComposer(
                  $db: $db,
                  $table: $db.teacherUnavailability,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> lessonTeachersRefs(
      Expression<bool> Function($$LessonTeachersTableFilterComposer f) f) {
    final $$LessonTeachersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessonTeachers,
        getReferencedColumn: (t) => t.teacherId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonTeachersTableFilterComposer(
              $db: $db,
              $table: $db.lessonTeachers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TeachersTableOrderingComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get abbreviation => $composableBuilder(
      column: $table.abbreviation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxPeriodsPerDay => $composableBuilder(
      column: $table.maxPeriodsPerDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxGapsPerDay => $composableBuilder(
      column: $table.maxGapsPerDay,
      builder: (column) => ColumnOrderings(column));
}

class $$TeachersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get abbreviation => $composableBuilder(
      column: $table.abbreviation, builder: (column) => column);

  GeneratedColumn<int> get maxPeriodsPerDay => $composableBuilder(
      column: $table.maxPeriodsPerDay, builder: (column) => column);

  GeneratedColumn<int> get maxGapsPerDay => $composableBuilder(
      column: $table.maxGapsPerDay, builder: (column) => column);

  Expression<T> teacherUnavailabilityRefs<T extends Object>(
      Expression<T> Function($$TeacherUnavailabilityTableAnnotationComposer a)
          f) {
    final $$TeacherUnavailabilityTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.teacherUnavailability,
            getReferencedColumn: (t) => t.teacherId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TeacherUnavailabilityTableAnnotationComposer(
                  $db: $db,
                  $table: $db.teacherUnavailability,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> lessonTeachersRefs<T extends Object>(
      Expression<T> Function($$LessonTeachersTableAnnotationComposer a) f) {
    final $$LessonTeachersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessonTeachers,
        getReferencedColumn: (t) => t.teacherId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonTeachersTableAnnotationComposer(
              $db: $db,
              $table: $db.lessonTeachers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TeachersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TeachersTable,
    TeacherRow,
    $$TeachersTableFilterComposer,
    $$TeachersTableOrderingComposer,
    $$TeachersTableAnnotationComposer,
    $$TeachersTableCreateCompanionBuilder,
    $$TeachersTableUpdateCompanionBuilder,
    (TeacherRow, $$TeachersTableReferences),
    TeacherRow,
    PrefetchHooks Function(
        {bool teacherUnavailabilityRefs, bool lessonTeachersRefs})> {
  $$TeachersTableTableManager(_$AppDatabase db, $TeachersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeachersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeachersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeachersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> abbreviation = const Value.absent(),
            Value<int?> maxPeriodsPerDay = const Value.absent(),
            Value<int?> maxGapsPerDay = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeachersCompanion(
            id: id,
            name: name,
            abbreviation: abbreviation,
            maxPeriodsPerDay: maxPeriodsPerDay,
            maxGapsPerDay: maxGapsPerDay,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String abbreviation,
            Value<int?> maxPeriodsPerDay = const Value.absent(),
            Value<int?> maxGapsPerDay = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeachersCompanion.insert(
            id: id,
            name: name,
            abbreviation: abbreviation,
            maxPeriodsPerDay: maxPeriodsPerDay,
            maxGapsPerDay: maxGapsPerDay,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TeachersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {teacherUnavailabilityRefs = false, lessonTeachersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (teacherUnavailabilityRefs) db.teacherUnavailability,
                if (lessonTeachersRefs) db.lessonTeachers
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (teacherUnavailabilityRefs)
                    await $_getPrefetchedData<TeacherRow, $TeachersTable,
                            TeacherUnavailabilityRow>(
                        currentTable: table,
                        referencedTable: $$TeachersTableReferences
                            ._teacherUnavailabilityRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TeachersTableReferences(db, table, p0)
                                .teacherUnavailabilityRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.teacherId == item.id),
                        typedResults: items),
                  if (lessonTeachersRefs)
                    await $_getPrefetchedData<TeacherRow, $TeachersTable,
                            LessonTeacher>(
                        currentTable: table,
                        referencedTable: $$TeachersTableReferences
                            ._lessonTeachersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TeachersTableReferences(db, table, p0)
                                .lessonTeachersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.teacherId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TeachersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TeachersTable,
    TeacherRow,
    $$TeachersTableFilterComposer,
    $$TeachersTableOrderingComposer,
    $$TeachersTableAnnotationComposer,
    $$TeachersTableCreateCompanionBuilder,
    $$TeachersTableUpdateCompanionBuilder,
    (TeacherRow, $$TeachersTableReferences),
    TeacherRow,
    PrefetchHooks Function(
        {bool teacherUnavailabilityRefs, bool lessonTeachersRefs})>;
typedef $$TeacherUnavailabilityTableCreateCompanionBuilder
    = TeacherUnavailabilityCompanion Function({
  required String id,
  required String teacherId,
  required int day,
  required int period,
  Value<int> state,
  Value<int> rowid,
});
typedef $$TeacherUnavailabilityTableUpdateCompanionBuilder
    = TeacherUnavailabilityCompanion Function({
  Value<String> id,
  Value<String> teacherId,
  Value<int> day,
  Value<int> period,
  Value<int> state,
  Value<int> rowid,
});

final class $$TeacherUnavailabilityTableReferences extends BaseReferences<
    _$AppDatabase, $TeacherUnavailabilityTable, TeacherUnavailabilityRow> {
  $$TeacherUnavailabilityTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TeachersTable _teacherIdTable(_$AppDatabase db) =>
      db.teachers.createAlias($_aliasNameGenerator(
          db.teacherUnavailability.teacherId, db.teachers.id));

  $$TeachersTableProcessedTableManager get teacherId {
    final $_column = $_itemColumn<String>('teacher_id')!;

    final manager = $$TeachersTableTableManager($_db, $_db.teachers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teacherIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TeacherUnavailabilityTableFilterComposer
    extends Composer<_$AppDatabase, $TeacherUnavailabilityTable> {
  $$TeacherUnavailabilityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  $$TeachersTableFilterComposer get teacherId {
    final $$TeachersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.teacherId,
        referencedTable: $db.teachers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TeachersTableFilterComposer(
              $db: $db,
              $table: $db.teachers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TeacherUnavailabilityTableOrderingComposer
    extends Composer<_$AppDatabase, $TeacherUnavailabilityTable> {
  $$TeacherUnavailabilityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  $$TeachersTableOrderingComposer get teacherId {
    final $$TeachersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.teacherId,
        referencedTable: $db.teachers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TeachersTableOrderingComposer(
              $db: $db,
              $table: $db.teachers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TeacherUnavailabilityTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeacherUnavailabilityTable> {
  $$TeacherUnavailabilityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  $$TeachersTableAnnotationComposer get teacherId {
    final $$TeachersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.teacherId,
        referencedTable: $db.teachers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TeachersTableAnnotationComposer(
              $db: $db,
              $table: $db.teachers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TeacherUnavailabilityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TeacherUnavailabilityTable,
    TeacherUnavailabilityRow,
    $$TeacherUnavailabilityTableFilterComposer,
    $$TeacherUnavailabilityTableOrderingComposer,
    $$TeacherUnavailabilityTableAnnotationComposer,
    $$TeacherUnavailabilityTableCreateCompanionBuilder,
    $$TeacherUnavailabilityTableUpdateCompanionBuilder,
    (TeacherUnavailabilityRow, $$TeacherUnavailabilityTableReferences),
    TeacherUnavailabilityRow,
    PrefetchHooks Function({bool teacherId})> {
  $$TeacherUnavailabilityTableTableManager(
      _$AppDatabase db, $TeacherUnavailabilityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeacherUnavailabilityTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$TeacherUnavailabilityTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeacherUnavailabilityTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> teacherId = const Value.absent(),
            Value<int> day = const Value.absent(),
            Value<int> period = const Value.absent(),
            Value<int> state = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeacherUnavailabilityCompanion(
            id: id,
            teacherId: teacherId,
            day: day,
            period: period,
            state: state,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String teacherId,
            required int day,
            required int period,
            Value<int> state = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeacherUnavailabilityCompanion.insert(
            id: id,
            teacherId: teacherId,
            day: day,
            period: period,
            state: state,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TeacherUnavailabilityTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({teacherId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (teacherId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.teacherId,
                    referencedTable: $$TeacherUnavailabilityTableReferences
                        ._teacherIdTable(db),
                    referencedColumn: $$TeacherUnavailabilityTableReferences
                        ._teacherIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TeacherUnavailabilityTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $TeacherUnavailabilityTable,
        TeacherUnavailabilityRow,
        $$TeacherUnavailabilityTableFilterComposer,
        $$TeacherUnavailabilityTableOrderingComposer,
        $$TeacherUnavailabilityTableAnnotationComposer,
        $$TeacherUnavailabilityTableCreateCompanionBuilder,
        $$TeacherUnavailabilityTableUpdateCompanionBuilder,
        (TeacherUnavailabilityRow, $$TeacherUnavailabilityTableReferences),
        TeacherUnavailabilityRow,
        PrefetchHooks Function({bool teacherId})>;
typedef $$LessonsTableCreateCompanionBuilder = LessonsCompanion Function({
  required String id,
  required String subjectId,
  Value<int> periodsPerWeek,
  Value<List<String>> teacherIds,
  Value<List<String>> classIds,
  Value<String?> classId,
  Value<String?> classDivisionId,
  Value<int> countPerWeek,
  Value<bool> isPinned,
  Value<int?> fixedDay,
  Value<int?> fixedPeriod,
  Value<int?> roomTypeId,
  Value<int> relationshipType,
  Value<String?> relationshipGroupKey,
  Value<int> rowid,
});
typedef $$LessonsTableUpdateCompanionBuilder = LessonsCompanion Function({
  Value<String> id,
  Value<String> subjectId,
  Value<int> periodsPerWeek,
  Value<List<String>> teacherIds,
  Value<List<String>> classIds,
  Value<String?> classId,
  Value<String?> classDivisionId,
  Value<int> countPerWeek,
  Value<bool> isPinned,
  Value<int?> fixedDay,
  Value<int?> fixedPeriod,
  Value<int?> roomTypeId,
  Value<int> relationshipType,
  Value<String?> relationshipGroupKey,
  Value<int> rowid,
});

final class $$LessonsTableReferences
    extends BaseReferences<_$AppDatabase, $LessonsTable, LessonRow> {
  $$LessonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) => db.subjects
      .createAlias($_aliasNameGenerator(db.lessons.subjectId, db.subjects.id));

  $$SubjectsTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<String>('subject_id')!;

    final manager = $$SubjectsTableTableManager($_db, $_db.subjects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $DivisionsTable _classDivisionIdTable(_$AppDatabase db) =>
      db.divisions.createAlias(
          $_aliasNameGenerator(db.lessons.classDivisionId, db.divisions.id));

  $$DivisionsTableProcessedTableManager? get classDivisionId {
    final $_column = $_itemColumn<String>('class_division_id');
    if ($_column == null) return null;
    final manager = $$DivisionsTableTableManager($_db, $_db.divisions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classDivisionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$CardsTable, List<CardRow>> _cardsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.cards,
          aliasName: $_aliasNameGenerator(db.lessons.id, db.cards.lessonId));

  $$CardsTableProcessedTableManager get cardsRefs {
    final manager = $$CardsTableTableManager($_db, $_db.cards)
        .filter((f) => f.lessonId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LessonClassesTable, List<LessonClassesData>>
      _lessonClassesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.lessonClasses,
              aliasName: $_aliasNameGenerator(
                  db.lessons.id, db.lessonClasses.lessonId));

  $$LessonClassesTableProcessedTableManager get lessonClassesRefs {
    final manager = $$LessonClassesTableTableManager($_db, $_db.lessonClasses)
        .filter((f) => f.lessonId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonClassesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LessonTeachersTable, List<LessonTeacher>>
      _lessonTeachersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.lessonTeachers,
              aliasName: $_aliasNameGenerator(
                  db.lessons.id, db.lessonTeachers.lessonId));

  $$LessonTeachersTableProcessedTableManager get lessonTeachersRefs {
    final manager = $$LessonTeachersTableTableManager($_db, $_db.lessonTeachers)
        .filter((f) => f.lessonId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonTeachersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LessonsTableFilterComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get periodsPerWeek => $composableBuilder(
      column: $table.periodsPerWeek,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get teacherIds => $composableBuilder(
          column: $table.teacherIds,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get classIds => $composableBuilder(
          column: $table.classIds,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get classId => $composableBuilder(
      column: $table.classId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get countPerWeek => $composableBuilder(
      column: $table.countPerWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fixedDay => $composableBuilder(
      column: $table.fixedDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fixedPeriod => $composableBuilder(
      column: $table.fixedPeriod, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get roomTypeId => $composableBuilder(
      column: $table.roomTypeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get relationshipType => $composableBuilder(
      column: $table.relationshipType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relationshipGroupKey => $composableBuilder(
      column: $table.relationshipGroupKey,
      builder: (column) => ColumnFilters(column));

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableFilterComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DivisionsTableFilterComposer get classDivisionId {
    final $$DivisionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classDivisionId,
        referencedTable: $db.divisions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DivisionsTableFilterComposer(
              $db: $db,
              $table: $db.divisions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> cardsRefs(
      Expression<bool> Function($$CardsTableFilterComposer f) f) {
    final $$CardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableFilterComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> lessonClassesRefs(
      Expression<bool> Function($$LessonClassesTableFilterComposer f) f) {
    final $$LessonClassesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessonClasses,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonClassesTableFilterComposer(
              $db: $db,
              $table: $db.lessonClasses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> lessonTeachersRefs(
      Expression<bool> Function($$LessonTeachersTableFilterComposer f) f) {
    final $$LessonTeachersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessonTeachers,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonTeachersTableFilterComposer(
              $db: $db,
              $table: $db.lessonTeachers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LessonsTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get periodsPerWeek => $composableBuilder(
      column: $table.periodsPerWeek,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teacherIds => $composableBuilder(
      column: $table.teacherIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get classIds => $composableBuilder(
      column: $table.classIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get classId => $composableBuilder(
      column: $table.classId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get countPerWeek => $composableBuilder(
      column: $table.countPerWeek,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fixedDay => $composableBuilder(
      column: $table.fixedDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fixedPeriod => $composableBuilder(
      column: $table.fixedPeriod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get roomTypeId => $composableBuilder(
      column: $table.roomTypeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get relationshipType => $composableBuilder(
      column: $table.relationshipType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relationshipGroupKey => $composableBuilder(
      column: $table.relationshipGroupKey,
      builder: (column) => ColumnOrderings(column));

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableOrderingComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DivisionsTableOrderingComposer get classDivisionId {
    final $$DivisionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classDivisionId,
        referencedTable: $db.divisions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DivisionsTableOrderingComposer(
              $db: $db,
              $table: $db.divisions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LessonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get periodsPerWeek => $composableBuilder(
      column: $table.periodsPerWeek, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get teacherIds =>
      $composableBuilder(
          column: $table.teacherIds, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get classIds =>
      $composableBuilder(column: $table.classIds, builder: (column) => column);

  GeneratedColumn<String> get classId =>
      $composableBuilder(column: $table.classId, builder: (column) => column);

  GeneratedColumn<int> get countPerWeek => $composableBuilder(
      column: $table.countPerWeek, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<int> get fixedDay =>
      $composableBuilder(column: $table.fixedDay, builder: (column) => column);

  GeneratedColumn<int> get fixedPeriod => $composableBuilder(
      column: $table.fixedPeriod, builder: (column) => column);

  GeneratedColumn<int> get roomTypeId => $composableBuilder(
      column: $table.roomTypeId, builder: (column) => column);

  GeneratedColumn<int> get relationshipType => $composableBuilder(
      column: $table.relationshipType, builder: (column) => column);

  GeneratedColumn<String> get relationshipGroupKey => $composableBuilder(
      column: $table.relationshipGroupKey, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectId,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DivisionsTableAnnotationComposer get classDivisionId {
    final $$DivisionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classDivisionId,
        referencedTable: $db.divisions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DivisionsTableAnnotationComposer(
              $db: $db,
              $table: $db.divisions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> cardsRefs<T extends Object>(
      Expression<T> Function($$CardsTableAnnotationComposer a) f) {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableAnnotationComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> lessonClassesRefs<T extends Object>(
      Expression<T> Function($$LessonClassesTableAnnotationComposer a) f) {
    final $$LessonClassesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessonClasses,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonClassesTableAnnotationComposer(
              $db: $db,
              $table: $db.lessonClasses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> lessonTeachersRefs<T extends Object>(
      Expression<T> Function($$LessonTeachersTableAnnotationComposer a) f) {
    final $$LessonTeachersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessonTeachers,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonTeachersTableAnnotationComposer(
              $db: $db,
              $table: $db.lessonTeachers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LessonsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LessonsTable,
    LessonRow,
    $$LessonsTableFilterComposer,
    $$LessonsTableOrderingComposer,
    $$LessonsTableAnnotationComposer,
    $$LessonsTableCreateCompanionBuilder,
    $$LessonsTableUpdateCompanionBuilder,
    (LessonRow, $$LessonsTableReferences),
    LessonRow,
    PrefetchHooks Function(
        {bool subjectId,
        bool classDivisionId,
        bool cardsRefs,
        bool lessonClassesRefs,
        bool lessonTeachersRefs})> {
  $$LessonsTableTableManager(_$AppDatabase db, $LessonsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> subjectId = const Value.absent(),
            Value<int> periodsPerWeek = const Value.absent(),
            Value<List<String>> teacherIds = const Value.absent(),
            Value<List<String>> classIds = const Value.absent(),
            Value<String?> classId = const Value.absent(),
            Value<String?> classDivisionId = const Value.absent(),
            Value<int> countPerWeek = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<int?> fixedDay = const Value.absent(),
            Value<int?> fixedPeriod = const Value.absent(),
            Value<int?> roomTypeId = const Value.absent(),
            Value<int> relationshipType = const Value.absent(),
            Value<String?> relationshipGroupKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonsCompanion(
            id: id,
            subjectId: subjectId,
            periodsPerWeek: periodsPerWeek,
            teacherIds: teacherIds,
            classIds: classIds,
            classId: classId,
            classDivisionId: classDivisionId,
            countPerWeek: countPerWeek,
            isPinned: isPinned,
            fixedDay: fixedDay,
            fixedPeriod: fixedPeriod,
            roomTypeId: roomTypeId,
            relationshipType: relationshipType,
            relationshipGroupKey: relationshipGroupKey,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String subjectId,
            Value<int> periodsPerWeek = const Value.absent(),
            Value<List<String>> teacherIds = const Value.absent(),
            Value<List<String>> classIds = const Value.absent(),
            Value<String?> classId = const Value.absent(),
            Value<String?> classDivisionId = const Value.absent(),
            Value<int> countPerWeek = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<int?> fixedDay = const Value.absent(),
            Value<int?> fixedPeriod = const Value.absent(),
            Value<int?> roomTypeId = const Value.absent(),
            Value<int> relationshipType = const Value.absent(),
            Value<String?> relationshipGroupKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonsCompanion.insert(
            id: id,
            subjectId: subjectId,
            periodsPerWeek: periodsPerWeek,
            teacherIds: teacherIds,
            classIds: classIds,
            classId: classId,
            classDivisionId: classDivisionId,
            countPerWeek: countPerWeek,
            isPinned: isPinned,
            fixedDay: fixedDay,
            fixedPeriod: fixedPeriod,
            roomTypeId: roomTypeId,
            relationshipType: relationshipType,
            relationshipGroupKey: relationshipGroupKey,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$LessonsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {subjectId = false,
              classDivisionId = false,
              cardsRefs = false,
              lessonClassesRefs = false,
              lessonTeachersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cardsRefs) db.cards,
                if (lessonClassesRefs) db.lessonClasses,
                if (lessonTeachersRefs) db.lessonTeachers
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (subjectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.subjectId,
                    referencedTable:
                        $$LessonsTableReferences._subjectIdTable(db),
                    referencedColumn:
                        $$LessonsTableReferences._subjectIdTable(db).id,
                  ) as T;
                }
                if (classDivisionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.classDivisionId,
                    referencedTable:
                        $$LessonsTableReferences._classDivisionIdTable(db),
                    referencedColumn:
                        $$LessonsTableReferences._classDivisionIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardsRefs)
                    await $_getPrefetchedData<LessonRow, $LessonsTable,
                            CardRow>(
                        currentTable: table,
                        referencedTable:
                            $$LessonsTableReferences._cardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LessonsTableReferences(db, table, p0).cardsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.lessonId == item.id),
                        typedResults: items),
                  if (lessonClassesRefs)
                    await $_getPrefetchedData<LessonRow, $LessonsTable,
                            LessonClassesData>(
                        currentTable: table,
                        referencedTable: $$LessonsTableReferences
                            ._lessonClassesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LessonsTableReferences(db, table, p0)
                                .lessonClassesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.lessonId == item.id),
                        typedResults: items),
                  if (lessonTeachersRefs)
                    await $_getPrefetchedData<LessonRow, $LessonsTable,
                            LessonTeacher>(
                        currentTable: table,
                        referencedTable: $$LessonsTableReferences
                            ._lessonTeachersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LessonsTableReferences(db, table, p0)
                                .lessonTeachersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.lessonId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LessonsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LessonsTable,
    LessonRow,
    $$LessonsTableFilterComposer,
    $$LessonsTableOrderingComposer,
    $$LessonsTableAnnotationComposer,
    $$LessonsTableCreateCompanionBuilder,
    $$LessonsTableUpdateCompanionBuilder,
    (LessonRow, $$LessonsTableReferences),
    LessonRow,
    PrefetchHooks Function(
        {bool subjectId,
        bool classDivisionId,
        bool cardsRefs,
        bool lessonClassesRefs,
        bool lessonTeachersRefs})>;
typedef $$CardsTableCreateCompanionBuilder = CardsCompanion Function({
  required String id,
  required String lessonId,
  required int dayIndex,
  required int periodIndex,
  Value<String?> roomId,
  Value<int> rowid,
});
typedef $$CardsTableUpdateCompanionBuilder = CardsCompanion Function({
  Value<String> id,
  Value<String> lessonId,
  Value<int> dayIndex,
  Value<int> periodIndex,
  Value<String?> roomId,
  Value<int> rowid,
});

final class $$CardsTableReferences
    extends BaseReferences<_$AppDatabase, $CardsTable, CardRow> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LessonsTable _lessonIdTable(_$AppDatabase db) => db.lessons
      .createAlias($_aliasNameGenerator(db.cards.lessonId, db.lessons.id));

  $$LessonsTableProcessedTableManager get lessonId {
    final $_column = $_itemColumn<String>('lesson_id')!;

    final manager = $$LessonsTableTableManager($_db, $_db.lessons)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayIndex => $composableBuilder(
      column: $table.dayIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get periodIndex => $composableBuilder(
      column: $table.periodIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get roomId => $composableBuilder(
      column: $table.roomId, builder: (column) => ColumnFilters(column));

  $$LessonsTableFilterComposer get lessonId {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableFilterComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayIndex => $composableBuilder(
      column: $table.dayIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get periodIndex => $composableBuilder(
      column: $table.periodIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roomId => $composableBuilder(
      column: $table.roomId, builder: (column) => ColumnOrderings(column));

  $$LessonsTableOrderingComposer get lessonId {
    final $$LessonsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableOrderingComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayIndex =>
      $composableBuilder(column: $table.dayIndex, builder: (column) => column);

  GeneratedColumn<int> get periodIndex => $composableBuilder(
      column: $table.periodIndex, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  $$LessonsTableAnnotationComposer get lessonId {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableAnnotationComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardsTable,
    CardRow,
    $$CardsTableFilterComposer,
    $$CardsTableOrderingComposer,
    $$CardsTableAnnotationComposer,
    $$CardsTableCreateCompanionBuilder,
    $$CardsTableUpdateCompanionBuilder,
    (CardRow, $$CardsTableReferences),
    CardRow,
    PrefetchHooks Function({bool lessonId})> {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> lessonId = const Value.absent(),
            Value<int> dayIndex = const Value.absent(),
            Value<int> periodIndex = const Value.absent(),
            Value<String?> roomId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardsCompanion(
            id: id,
            lessonId: lessonId,
            dayIndex: dayIndex,
            periodIndex: periodIndex,
            roomId: roomId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String lessonId,
            required int dayIndex,
            required int periodIndex,
            Value<String?> roomId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardsCompanion.insert(
            id: id,
            lessonId: lessonId,
            dayIndex: dayIndex,
            periodIndex: periodIndex,
            roomId: roomId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$CardsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({lessonId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (lessonId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lessonId,
                    referencedTable: $$CardsTableReferences._lessonIdTable(db),
                    referencedColumn:
                        $$CardsTableReferences._lessonIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CardsTable,
    CardRow,
    $$CardsTableFilterComposer,
    $$CardsTableOrderingComposer,
    $$CardsTableAnnotationComposer,
    $$CardsTableCreateCompanionBuilder,
    $$CardsTableUpdateCompanionBuilder,
    (CardRow, $$CardsTableReferences),
    CardRow,
    PrefetchHooks Function({bool lessonId})>;
typedef $$LessonClassesTableCreateCompanionBuilder = LessonClassesCompanion
    Function({
  required String lessonId,
  required String classId,
  Value<int> rowid,
});
typedef $$LessonClassesTableUpdateCompanionBuilder = LessonClassesCompanion
    Function({
  Value<String> lessonId,
  Value<String> classId,
  Value<int> rowid,
});

final class $$LessonClassesTableReferences extends BaseReferences<_$AppDatabase,
    $LessonClassesTable, LessonClassesData> {
  $$LessonClassesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LessonsTable _lessonIdTable(_$AppDatabase db) =>
      db.lessons.createAlias(
          $_aliasNameGenerator(db.lessonClasses.lessonId, db.lessons.id));

  $$LessonsTableProcessedTableManager get lessonId {
    final $_column = $_itemColumn<String>('lesson_id')!;

    final manager = $$LessonsTableTableManager($_db, $_db.lessons)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ClassesTable _classIdTable(_$AppDatabase db) =>
      db.classes.createAlias(
          $_aliasNameGenerator(db.lessonClasses.classId, db.classes.id));

  $$ClassesTableProcessedTableManager get classId {
    final $_column = $_itemColumn<String>('class_id')!;

    final manager = $$ClassesTableTableManager($_db, $_db.classes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LessonClassesTableFilterComposer
    extends Composer<_$AppDatabase, $LessonClassesTable> {
  $$LessonClassesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$LessonsTableFilterComposer get lessonId {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableFilterComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ClassesTableFilterComposer get classId {
    final $$ClassesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classId,
        referencedTable: $db.classes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassesTableFilterComposer(
              $db: $db,
              $table: $db.classes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LessonClassesTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonClassesTable> {
  $$LessonClassesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$LessonsTableOrderingComposer get lessonId {
    final $$LessonsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableOrderingComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ClassesTableOrderingComposer get classId {
    final $$ClassesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classId,
        referencedTable: $db.classes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassesTableOrderingComposer(
              $db: $db,
              $table: $db.classes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LessonClassesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonClassesTable> {
  $$LessonClassesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$LessonsTableAnnotationComposer get lessonId {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableAnnotationComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ClassesTableAnnotationComposer get classId {
    final $$ClassesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classId,
        referencedTable: $db.classes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassesTableAnnotationComposer(
              $db: $db,
              $table: $db.classes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LessonClassesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LessonClassesTable,
    LessonClassesData,
    $$LessonClassesTableFilterComposer,
    $$LessonClassesTableOrderingComposer,
    $$LessonClassesTableAnnotationComposer,
    $$LessonClassesTableCreateCompanionBuilder,
    $$LessonClassesTableUpdateCompanionBuilder,
    (LessonClassesData, $$LessonClassesTableReferences),
    LessonClassesData,
    PrefetchHooks Function({bool lessonId, bool classId})> {
  $$LessonClassesTableTableManager(_$AppDatabase db, $LessonClassesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonClassesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonClassesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonClassesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> lessonId = const Value.absent(),
            Value<String> classId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonClassesCompanion(
            lessonId: lessonId,
            classId: classId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String lessonId,
            required String classId,
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonClassesCompanion.insert(
            lessonId: lessonId,
            classId: classId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LessonClassesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({lessonId = false, classId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (lessonId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lessonId,
                    referencedTable:
                        $$LessonClassesTableReferences._lessonIdTable(db),
                    referencedColumn:
                        $$LessonClassesTableReferences._lessonIdTable(db).id,
                  ) as T;
                }
                if (classId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.classId,
                    referencedTable:
                        $$LessonClassesTableReferences._classIdTable(db),
                    referencedColumn:
                        $$LessonClassesTableReferences._classIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LessonClassesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LessonClassesTable,
    LessonClassesData,
    $$LessonClassesTableFilterComposer,
    $$LessonClassesTableOrderingComposer,
    $$LessonClassesTableAnnotationComposer,
    $$LessonClassesTableCreateCompanionBuilder,
    $$LessonClassesTableUpdateCompanionBuilder,
    (LessonClassesData, $$LessonClassesTableReferences),
    LessonClassesData,
    PrefetchHooks Function({bool lessonId, bool classId})>;
typedef $$LessonTeachersTableCreateCompanionBuilder = LessonTeachersCompanion
    Function({
  required String lessonId,
  required String teacherId,
  Value<int> rowid,
});
typedef $$LessonTeachersTableUpdateCompanionBuilder = LessonTeachersCompanion
    Function({
  Value<String> lessonId,
  Value<String> teacherId,
  Value<int> rowid,
});

final class $$LessonTeachersTableReferences
    extends BaseReferences<_$AppDatabase, $LessonTeachersTable, LessonTeacher> {
  $$LessonTeachersTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LessonsTable _lessonIdTable(_$AppDatabase db) =>
      db.lessons.createAlias(
          $_aliasNameGenerator(db.lessonTeachers.lessonId, db.lessons.id));

  $$LessonsTableProcessedTableManager get lessonId {
    final $_column = $_itemColumn<String>('lesson_id')!;

    final manager = $$LessonsTableTableManager($_db, $_db.lessons)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TeachersTable _teacherIdTable(_$AppDatabase db) =>
      db.teachers.createAlias(
          $_aliasNameGenerator(db.lessonTeachers.teacherId, db.teachers.id));

  $$TeachersTableProcessedTableManager get teacherId {
    final $_column = $_itemColumn<String>('teacher_id')!;

    final manager = $$TeachersTableTableManager($_db, $_db.teachers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teacherIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LessonTeachersTableFilterComposer
    extends Composer<_$AppDatabase, $LessonTeachersTable> {
  $$LessonTeachersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$LessonsTableFilterComposer get lessonId {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableFilterComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TeachersTableFilterComposer get teacherId {
    final $$TeachersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.teacherId,
        referencedTable: $db.teachers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TeachersTableFilterComposer(
              $db: $db,
              $table: $db.teachers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LessonTeachersTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonTeachersTable> {
  $$LessonTeachersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$LessonsTableOrderingComposer get lessonId {
    final $$LessonsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableOrderingComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TeachersTableOrderingComposer get teacherId {
    final $$TeachersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.teacherId,
        referencedTable: $db.teachers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TeachersTableOrderingComposer(
              $db: $db,
              $table: $db.teachers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LessonTeachersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonTeachersTable> {
  $$LessonTeachersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$LessonsTableAnnotationComposer get lessonId {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableAnnotationComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TeachersTableAnnotationComposer get teacherId {
    final $$TeachersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.teacherId,
        referencedTable: $db.teachers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TeachersTableAnnotationComposer(
              $db: $db,
              $table: $db.teachers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LessonTeachersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LessonTeachersTable,
    LessonTeacher,
    $$LessonTeachersTableFilterComposer,
    $$LessonTeachersTableOrderingComposer,
    $$LessonTeachersTableAnnotationComposer,
    $$LessonTeachersTableCreateCompanionBuilder,
    $$LessonTeachersTableUpdateCompanionBuilder,
    (LessonTeacher, $$LessonTeachersTableReferences),
    LessonTeacher,
    PrefetchHooks Function({bool lessonId, bool teacherId})> {
  $$LessonTeachersTableTableManager(
      _$AppDatabase db, $LessonTeachersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonTeachersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonTeachersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonTeachersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> lessonId = const Value.absent(),
            Value<String> teacherId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonTeachersCompanion(
            lessonId: lessonId,
            teacherId: teacherId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String lessonId,
            required String teacherId,
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonTeachersCompanion.insert(
            lessonId: lessonId,
            teacherId: teacherId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LessonTeachersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({lessonId = false, teacherId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (lessonId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lessonId,
                    referencedTable:
                        $$LessonTeachersTableReferences._lessonIdTable(db),
                    referencedColumn:
                        $$LessonTeachersTableReferences._lessonIdTable(db).id,
                  ) as T;
                }
                if (teacherId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.teacherId,
                    referencedTable:
                        $$LessonTeachersTableReferences._teacherIdTable(db),
                    referencedColumn:
                        $$LessonTeachersTableReferences._teacherIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LessonTeachersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LessonTeachersTable,
    LessonTeacher,
    $$LessonTeachersTableFilterComposer,
    $$LessonTeachersTableOrderingComposer,
    $$LessonTeachersTableAnnotationComposer,
    $$LessonTeachersTableCreateCompanionBuilder,
    $$LessonTeachersTableUpdateCompanionBuilder,
    (LessonTeacher, $$LessonTeachersTableReferences),
    LessonTeacher,
    PrefetchHooks Function({bool lessonId, bool teacherId})>;
typedef $$EntityTimeOffTableCreateCompanionBuilder = EntityTimeOffCompanion
    Function({
  required String id,
  required String entityType,
  required String entityId,
  required int day,
  required int period,
  Value<int> state,
  Value<int> rowid,
});
typedef $$EntityTimeOffTableUpdateCompanionBuilder = EntityTimeOffCompanion
    Function({
  Value<String> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<int> day,
  Value<int> period,
  Value<int> state,
  Value<int> rowid,
});

class $$EntityTimeOffTableFilterComposer
    extends Composer<_$AppDatabase, $EntityTimeOffTable> {
  $$EntityTimeOffTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));
}

class $$EntityTimeOffTableOrderingComposer
    extends Composer<_$AppDatabase, $EntityTimeOffTable> {
  $$EntityTimeOffTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));
}

class $$EntityTimeOffTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntityTimeOffTable> {
  $$EntityTimeOffTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $$EntityTimeOffTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EntityTimeOffTable,
    EntityTimeOffData,
    $$EntityTimeOffTableFilterComposer,
    $$EntityTimeOffTableOrderingComposer,
    $$EntityTimeOffTableAnnotationComposer,
    $$EntityTimeOffTableCreateCompanionBuilder,
    $$EntityTimeOffTableUpdateCompanionBuilder,
    (
      EntityTimeOffData,
      BaseReferences<_$AppDatabase, $EntityTimeOffTable, EntityTimeOffData>
    ),
    EntityTimeOffData,
    PrefetchHooks Function()> {
  $$EntityTimeOffTableTableManager(_$AppDatabase db, $EntityTimeOffTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntityTimeOffTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntityTimeOffTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntityTimeOffTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<int> day = const Value.absent(),
            Value<int> period = const Value.absent(),
            Value<int> state = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntityTimeOffCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            day: day,
            period: period,
            state: state,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String entityType,
            required String entityId,
            required int day,
            required int period,
            Value<int> state = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntityTimeOffCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            day: day,
            period: period,
            state: state,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EntityTimeOffTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EntityTimeOffTable,
    EntityTimeOffData,
    $$EntityTimeOffTableFilterComposer,
    $$EntityTimeOffTableOrderingComposer,
    $$EntityTimeOffTableAnnotationComposer,
    $$EntityTimeOffTableCreateCompanionBuilder,
    $$EntityTimeOffTableUpdateCompanionBuilder,
    (
      EntityTimeOffData,
      BaseReferences<_$AppDatabase, $EntityTimeOffTable, EntityTimeOffData>
    ),
    EntityTimeOffData,
    PrefetchHooks Function()>;
typedef $$SoftConstraintProfilesTableCreateCompanionBuilder
    = SoftConstraintProfilesCompanion Function({
  required String id,
  required String entityType,
  required String entityId,
  Value<int?> maxGapsPerDay,
  Value<int?> maxConsecutivePeriods,
  Value<int> rowid,
});
typedef $$SoftConstraintProfilesTableUpdateCompanionBuilder
    = SoftConstraintProfilesCompanion Function({
  Value<String> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<int?> maxGapsPerDay,
  Value<int?> maxConsecutivePeriods,
  Value<int> rowid,
});

class $$SoftConstraintProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $SoftConstraintProfilesTable> {
  $$SoftConstraintProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxGapsPerDay => $composableBuilder(
      column: $table.maxGapsPerDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxConsecutivePeriods => $composableBuilder(
      column: $table.maxConsecutivePeriods,
      builder: (column) => ColumnFilters(column));
}

class $$SoftConstraintProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $SoftConstraintProfilesTable> {
  $$SoftConstraintProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxGapsPerDay => $composableBuilder(
      column: $table.maxGapsPerDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxConsecutivePeriods => $composableBuilder(
      column: $table.maxConsecutivePeriods,
      builder: (column) => ColumnOrderings(column));
}

class $$SoftConstraintProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SoftConstraintProfilesTable> {
  $$SoftConstraintProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get maxGapsPerDay => $composableBuilder(
      column: $table.maxGapsPerDay, builder: (column) => column);

  GeneratedColumn<int> get maxConsecutivePeriods => $composableBuilder(
      column: $table.maxConsecutivePeriods, builder: (column) => column);
}

class $$SoftConstraintProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SoftConstraintProfilesTable,
    SoftConstraintProfile,
    $$SoftConstraintProfilesTableFilterComposer,
    $$SoftConstraintProfilesTableOrderingComposer,
    $$SoftConstraintProfilesTableAnnotationComposer,
    $$SoftConstraintProfilesTableCreateCompanionBuilder,
    $$SoftConstraintProfilesTableUpdateCompanionBuilder,
    (
      SoftConstraintProfile,
      BaseReferences<_$AppDatabase, $SoftConstraintProfilesTable,
          SoftConstraintProfile>
    ),
    SoftConstraintProfile,
    PrefetchHooks Function()> {
  $$SoftConstraintProfilesTableTableManager(
      _$AppDatabase db, $SoftConstraintProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SoftConstraintProfilesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SoftConstraintProfilesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SoftConstraintProfilesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<int?> maxGapsPerDay = const Value.absent(),
            Value<int?> maxConsecutivePeriods = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SoftConstraintProfilesCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            maxGapsPerDay: maxGapsPerDay,
            maxConsecutivePeriods: maxConsecutivePeriods,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String entityType,
            required String entityId,
            Value<int?> maxGapsPerDay = const Value.absent(),
            Value<int?> maxConsecutivePeriods = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SoftConstraintProfilesCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            maxGapsPerDay: maxGapsPerDay,
            maxConsecutivePeriods: maxConsecutivePeriods,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SoftConstraintProfilesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $SoftConstraintProfilesTable,
        SoftConstraintProfile,
        $$SoftConstraintProfilesTableFilterComposer,
        $$SoftConstraintProfilesTableOrderingComposer,
        $$SoftConstraintProfilesTableAnnotationComposer,
        $$SoftConstraintProfilesTableCreateCompanionBuilder,
        $$SoftConstraintProfilesTableUpdateCompanionBuilder,
        (
          SoftConstraintProfile,
          BaseReferences<_$AppDatabase, $SoftConstraintProfilesTable,
              SoftConstraintProfile>
        ),
        SoftConstraintProfile,
        PrefetchHooks Function()>;
typedef $$AppStateTableCreateCompanionBuilder = AppStateCompanion Function({
  Value<int> id,
  required String plannerJson,
  Value<DateTime> updatedAt,
});
typedef $$AppStateTableUpdateCompanionBuilder = AppStateCompanion Function({
  Value<int> id,
  Value<String> plannerJson,
  Value<DateTime> updatedAt,
});

class $$AppStateTableFilterComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plannerJson => $composableBuilder(
      column: $table.plannerJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppStateTableOrderingComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plannerJson => $composableBuilder(
      column: $table.plannerJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plannerJson => $composableBuilder(
      column: $table.plannerJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppStateTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppStateTable,
    AppStateData,
    $$AppStateTableFilterComposer,
    $$AppStateTableOrderingComposer,
    $$AppStateTableAnnotationComposer,
    $$AppStateTableCreateCompanionBuilder,
    $$AppStateTableUpdateCompanionBuilder,
    (AppStateData, BaseReferences<_$AppDatabase, $AppStateTable, AppStateData>),
    AppStateData,
    PrefetchHooks Function()> {
  $$AppStateTableTableManager(_$AppDatabase db, $AppStateTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> plannerJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              AppStateCompanion(
            id: id,
            plannerJson: plannerJson,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String plannerJson,
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              AppStateCompanion.insert(
            id: id,
            plannerJson: plannerJson,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppStateTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppStateTable,
    AppStateData,
    $$AppStateTableFilterComposer,
    $$AppStateTableOrderingComposer,
    $$AppStateTableAnnotationComposer,
    $$AppStateTableCreateCompanionBuilder,
    $$AppStateTableUpdateCompanionBuilder,
    (AppStateData, BaseReferences<_$AppDatabase, $AppStateTable, AppStateData>),
    AppStateData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$ClassesTableTableManager get classes =>
      $$ClassesTableTableManager(_db, _db.classes);
  $$DivisionsTableTableManager get divisions =>
      $$DivisionsTableTableManager(_db, _db.divisions);
  $$TeachersTableTableManager get teachers =>
      $$TeachersTableTableManager(_db, _db.teachers);
  $$TeacherUnavailabilityTableTableManager get teacherUnavailability =>
      $$TeacherUnavailabilityTableTableManager(_db, _db.teacherUnavailability);
  $$LessonsTableTableManager get lessons =>
      $$LessonsTableTableManager(_db, _db.lessons);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$LessonClassesTableTableManager get lessonClasses =>
      $$LessonClassesTableTableManager(_db, _db.lessonClasses);
  $$LessonTeachersTableTableManager get lessonTeachers =>
      $$LessonTeachersTableTableManager(_db, _db.lessonTeachers);
  $$EntityTimeOffTableTableManager get entityTimeOff =>
      $$EntityTimeOffTableTableManager(_db, _db.entityTimeOff);
  $$SoftConstraintProfilesTableTableManager get softConstraintProfiles =>
      $$SoftConstraintProfilesTableTableManager(
          _db, _db.softConstraintProfiles);
  $$AppStateTableTableManager get appState =>
      $$AppStateTableTableManager(_db, _db.appState);
}
