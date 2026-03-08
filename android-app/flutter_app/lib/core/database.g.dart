// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
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
  VerificationContext validateIntegrity(Insertable<Subject> instance,
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
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
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

class Subject extends DataClass implements Insertable<Subject> {
  final String id;
  final String name;
  final String abbr;
  final String? groupId;
  final int? roomTypeId;
  final int color;
  const Subject(
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

  factory Subject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
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

  Subject copyWith(
          {String? id,
          String? name,
          String? abbr,
          Value<String?> groupId = const Value.absent(),
          Value<int?> roomTypeId = const Value.absent(),
          int? color}) =>
      Subject(
        id: id ?? this.id,
        name: name ?? this.name,
        abbr: abbr ?? this.abbr,
        groupId: groupId.present ? groupId.value : this.groupId,
        roomTypeId: roomTypeId.present ? roomTypeId.value : this.roomTypeId,
        color: color ?? this.color,
      );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
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
    return (StringBuffer('Subject(')
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
      (other is Subject &&
          other.id == this.id &&
          other.name == this.name &&
          other.abbr == this.abbr &&
          other.groupId == this.groupId &&
          other.roomTypeId == this.roomTypeId &&
          other.color == this.color);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
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
  static Insertable<Subject> custom({
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

class $ClassesTable extends Classes with TableInfo<$ClassesTable, ClassesData> {
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
  VerificationContext validateIntegrity(Insertable<ClassesData> instance,
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
  ClassesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassesData(
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

class ClassesData extends DataClass implements Insertable<ClassesData> {
  final String id;
  final String name;
  final String abbr;
  const ClassesData({required this.id, required this.name, required this.abbr});
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

  factory ClassesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassesData(
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

  ClassesData copyWith({String? id, String? name, String? abbr}) => ClassesData(
        id: id ?? this.id,
        name: name ?? this.name,
        abbr: abbr ?? this.abbr,
      );
  ClassesData copyWithCompanion(ClassesCompanion data) {
    return ClassesData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      abbr: data.abbr.present ? data.abbr.value : this.abbr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassesData(')
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
      (other is ClassesData &&
          other.id == this.id &&
          other.name == this.name &&
          other.abbr == this.abbr);
}

class ClassesCompanion extends UpdateCompanion<ClassesData> {
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
  static Insertable<ClassesData> custom({
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

class $ClassDivisionsTable extends ClassDivisions
    with TableInfo<$ClassDivisionsTable, ClassDivision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassDivisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, classId, name, code];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_divisions';
  @override
  VerificationContext validateIntegrity(Insertable<ClassDivision> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassDivision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassDivision(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
    );
  }

  @override
  $ClassDivisionsTable createAlias(String alias) {
    return $ClassDivisionsTable(attachedDatabase, alias);
  }
}

class ClassDivision extends DataClass implements Insertable<ClassDivision> {
  final String id;
  final String classId;
  final String name;
  final String code;
  const ClassDivision(
      {required this.id,
      required this.classId,
      required this.name,
      required this.code});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['class_id'] = Variable<String>(classId);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    return map;
  }

  ClassDivisionsCompanion toCompanion(bool nullToAbsent) {
    return ClassDivisionsCompanion(
      id: Value(id),
      classId: Value(classId),
      name: Value(name),
      code: Value(code),
    );
  }

  factory ClassDivision.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassDivision(
      id: serializer.fromJson<String>(json['id']),
      classId: serializer.fromJson<String>(json['classId']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'classId': serializer.toJson<String>(classId),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
    };
  }

  ClassDivision copyWith(
          {String? id, String? classId, String? name, String? code}) =>
      ClassDivision(
        id: id ?? this.id,
        classId: classId ?? this.classId,
        name: name ?? this.name,
        code: code ?? this.code,
      );
  ClassDivision copyWithCompanion(ClassDivisionsCompanion data) {
    return ClassDivision(
      id: data.id.present ? data.id.value : this.id,
      classId: data.classId.present ? data.classId.value : this.classId,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassDivision(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('name: $name, ')
          ..write('code: $code')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, classId, name, code);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassDivision &&
          other.id == this.id &&
          other.classId == this.classId &&
          other.name == this.name &&
          other.code == this.code);
}

class ClassDivisionsCompanion extends UpdateCompanion<ClassDivision> {
  final Value<String> id;
  final Value<String> classId;
  final Value<String> name;
  final Value<String> code;
  final Value<int> rowid;
  const ClassDivisionsCompanion({
    this.id = const Value.absent(),
    this.classId = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassDivisionsCompanion.insert({
    required String id,
    required String classId,
    required String name,
    required String code,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        classId = Value(classId),
        name = Value(name),
        code = Value(code);
  static Insertable<ClassDivision> custom({
    Expression<String>? id,
    Expression<String>? classId,
    Expression<String>? name,
    Expression<String>? code,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classId != null) 'class_id': classId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassDivisionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? classId,
      Value<String>? name,
      Value<String>? code,
      Value<int>? rowid}) {
    return ClassDivisionsCompanion(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      code: code ?? this.code,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassDivisionsCompanion(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonsTable extends Lessons with TableInfo<$LessonsTable, Lesson> {
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
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES class_divisions (id)'));
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
  VerificationContext validateIntegrity(Insertable<Lesson> instance,
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
  Lesson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lesson(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subjectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_id'])!,
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
}

class Lesson extends DataClass implements Insertable<Lesson> {
  final String id;
  final String subjectId;
  final String? classId;
  final String? classDivisionId;
  final int countPerWeek;
  final bool isPinned;
  final int? fixedDay;
  final int? fixedPeriod;
  final int? roomTypeId;
  final int relationshipType;
  final String? relationshipGroupKey;
  const Lesson(
      {required this.id,
      required this.subjectId,
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

  factory Lesson.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lesson(
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
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

  Lesson copyWith(
          {String? id,
          String? subjectId,
          Value<String?> classId = const Value.absent(),
          Value<String?> classDivisionId = const Value.absent(),
          int? countPerWeek,
          bool? isPinned,
          Value<int?> fixedDay = const Value.absent(),
          Value<int?> fixedPeriod = const Value.absent(),
          Value<int?> roomTypeId = const Value.absent(),
          int? relationshipType,
          Value<String?> relationshipGroupKey = const Value.absent()}) =>
      Lesson(
        id: id ?? this.id,
        subjectId: subjectId ?? this.subjectId,
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
  Lesson copyWithCompanion(LessonsCompanion data) {
    return Lesson(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
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
    return (StringBuffer('Lesson(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
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
      (other is Lesson &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
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

class LessonsCompanion extends UpdateCompanion<Lesson> {
  final Value<String> id;
  final Value<String> subjectId;
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
  static Insertable<Lesson> custom({
    Expression<String>? id,
    Expression<String>? subjectId,
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
      type: DriftSqlType.string, requiredDuringInsert: true);
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
  late final $ClassDivisionsTable classDivisions = $ClassDivisionsTable(this);
  late final $LessonsTable lessons = $LessonsTable(this);
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
        classDivisions,
        lessons,
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
    extends BaseReferences<_$AppDatabase, $SubjectsTable, Subject> {
  $$SubjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LessonsTable, List<Lesson>> _lessonsRefsTable(
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
    Subject,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (Subject, $$SubjectsTableReferences),
    Subject,
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
                    await $_getPrefetchedData<Subject, $SubjectsTable, Lesson>(
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
    Subject,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (Subject, $$SubjectsTableReferences),
    Subject,
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
    extends BaseReferences<_$AppDatabase, $ClassesTable, ClassesData> {
  $$ClassesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ClassDivisionsTable, List<ClassDivision>>
      _classDivisionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.classDivisions,
              aliasName: $_aliasNameGenerator(
                  db.classes.id, db.classDivisions.classId));

  $$ClassDivisionsTableProcessedTableManager get classDivisionsRefs {
    final manager = $$ClassDivisionsTableTableManager($_db, $_db.classDivisions)
        .filter((f) => f.classId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_classDivisionsRefsTable($_db));
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

  Expression<bool> classDivisionsRefs(
      Expression<bool> Function($$ClassDivisionsTableFilterComposer f) f) {
    final $$ClassDivisionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.classDivisions,
        getReferencedColumn: (t) => t.classId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassDivisionsTableFilterComposer(
              $db: $db,
              $table: $db.classDivisions,
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

  Expression<T> classDivisionsRefs<T extends Object>(
      Expression<T> Function($$ClassDivisionsTableAnnotationComposer a) f) {
    final $$ClassDivisionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.classDivisions,
        getReferencedColumn: (t) => t.classId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassDivisionsTableAnnotationComposer(
              $db: $db,
              $table: $db.classDivisions,
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
    ClassesData,
    $$ClassesTableFilterComposer,
    $$ClassesTableOrderingComposer,
    $$ClassesTableAnnotationComposer,
    $$ClassesTableCreateCompanionBuilder,
    $$ClassesTableUpdateCompanionBuilder,
    (ClassesData, $$ClassesTableReferences),
    ClassesData,
    PrefetchHooks Function({bool classDivisionsRefs, bool lessonClassesRefs})> {
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
              {classDivisionsRefs = false, lessonClassesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (classDivisionsRefs) db.classDivisions,
                if (lessonClassesRefs) db.lessonClasses
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (classDivisionsRefs)
                    await $_getPrefetchedData<ClassesData, $ClassesTable,
                            ClassDivision>(
                        currentTable: table,
                        referencedTable: $$ClassesTableReferences
                            ._classDivisionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClassesTableReferences(db, table, p0)
                                .classDivisionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.classId == item.id),
                        typedResults: items),
                  if (lessonClassesRefs)
                    await $_getPrefetchedData<ClassesData, $ClassesTable,
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
    ClassesData,
    $$ClassesTableFilterComposer,
    $$ClassesTableOrderingComposer,
    $$ClassesTableAnnotationComposer,
    $$ClassesTableCreateCompanionBuilder,
    $$ClassesTableUpdateCompanionBuilder,
    (ClassesData, $$ClassesTableReferences),
    ClassesData,
    PrefetchHooks Function({bool classDivisionsRefs, bool lessonClassesRefs})>;
typedef $$ClassDivisionsTableCreateCompanionBuilder = ClassDivisionsCompanion
    Function({
  required String id,
  required String classId,
  required String name,
  required String code,
  Value<int> rowid,
});
typedef $$ClassDivisionsTableUpdateCompanionBuilder = ClassDivisionsCompanion
    Function({
  Value<String> id,
  Value<String> classId,
  Value<String> name,
  Value<String> code,
  Value<int> rowid,
});

final class $$ClassDivisionsTableReferences
    extends BaseReferences<_$AppDatabase, $ClassDivisionsTable, ClassDivision> {
  $$ClassDivisionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ClassesTable _classIdTable(_$AppDatabase db) =>
      db.classes.createAlias(
          $_aliasNameGenerator(db.classDivisions.classId, db.classes.id));

  $$ClassesTableProcessedTableManager get classId {
    final $_column = $_itemColumn<String>('class_id')!;

    final manager = $$ClassesTableTableManager($_db, $_db.classes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$LessonsTable, List<Lesson>> _lessonsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lessons,
          aliasName: $_aliasNameGenerator(
              db.classDivisions.id, db.lessons.classDivisionId));

  $$LessonsTableProcessedTableManager get lessonsRefs {
    final manager = $$LessonsTableTableManager($_db, $_db.lessons).filter(
        (f) => f.classDivisionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ClassDivisionsTableFilterComposer
    extends Composer<_$AppDatabase, $ClassDivisionsTable> {
  $$ClassDivisionsTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

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

class $$ClassDivisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassDivisionsTable> {
  $$ClassDivisionsTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

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

class $$ClassDivisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassDivisionsTable> {
  $$ClassDivisionsTableAnnotationComposer({
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

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

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

class $$ClassDivisionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClassDivisionsTable,
    ClassDivision,
    $$ClassDivisionsTableFilterComposer,
    $$ClassDivisionsTableOrderingComposer,
    $$ClassDivisionsTableAnnotationComposer,
    $$ClassDivisionsTableCreateCompanionBuilder,
    $$ClassDivisionsTableUpdateCompanionBuilder,
    (ClassDivision, $$ClassDivisionsTableReferences),
    ClassDivision,
    PrefetchHooks Function({bool classId, bool lessonsRefs})> {
  $$ClassDivisionsTableTableManager(
      _$AppDatabase db, $ClassDivisionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassDivisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassDivisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassDivisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> classId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClassDivisionsCompanion(
            id: id,
            classId: classId,
            name: name,
            code: code,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String classId,
            required String name,
            required String code,
            Value<int> rowid = const Value.absent(),
          }) =>
              ClassDivisionsCompanion.insert(
            id: id,
            classId: classId,
            name: name,
            code: code,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ClassDivisionsTableReferences(db, table, e)
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
                        $$ClassDivisionsTableReferences._classIdTable(db),
                    referencedColumn:
                        $$ClassDivisionsTableReferences._classIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lessonsRefs)
                    await $_getPrefetchedData<ClassDivision,
                            $ClassDivisionsTable, Lesson>(
                        currentTable: table,
                        referencedTable: $$ClassDivisionsTableReferences
                            ._lessonsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClassDivisionsTableReferences(db, table, p0)
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

typedef $$ClassDivisionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClassDivisionsTable,
    ClassDivision,
    $$ClassDivisionsTableFilterComposer,
    $$ClassDivisionsTableOrderingComposer,
    $$ClassDivisionsTableAnnotationComposer,
    $$ClassDivisionsTableCreateCompanionBuilder,
    $$ClassDivisionsTableUpdateCompanionBuilder,
    (ClassDivision, $$ClassDivisionsTableReferences),
    ClassDivision,
    PrefetchHooks Function({bool classId, bool lessonsRefs})>;
typedef $$LessonsTableCreateCompanionBuilder = LessonsCompanion Function({
  required String id,
  required String subjectId,
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
    extends BaseReferences<_$AppDatabase, $LessonsTable, Lesson> {
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

  static $ClassDivisionsTable _classDivisionIdTable(_$AppDatabase db) =>
      db.classDivisions.createAlias($_aliasNameGenerator(
          db.lessons.classDivisionId, db.classDivisions.id));

  $$ClassDivisionsTableProcessedTableManager? get classDivisionId {
    final $_column = $_itemColumn<String>('class_division_id');
    if ($_column == null) return null;
    final manager = $$ClassDivisionsTableTableManager($_db, $_db.classDivisions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classDivisionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
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

  $$ClassDivisionsTableFilterComposer get classDivisionId {
    final $$ClassDivisionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classDivisionId,
        referencedTable: $db.classDivisions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassDivisionsTableFilterComposer(
              $db: $db,
              $table: $db.classDivisions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
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

  $$ClassDivisionsTableOrderingComposer get classDivisionId {
    final $$ClassDivisionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classDivisionId,
        referencedTable: $db.classDivisions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassDivisionsTableOrderingComposer(
              $db: $db,
              $table: $db.classDivisions,
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

  $$ClassDivisionsTableAnnotationComposer get classDivisionId {
    final $$ClassDivisionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.classDivisionId,
        referencedTable: $db.classDivisions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClassDivisionsTableAnnotationComposer(
              $db: $db,
              $table: $db.classDivisions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
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
    Lesson,
    $$LessonsTableFilterComposer,
    $$LessonsTableOrderingComposer,
    $$LessonsTableAnnotationComposer,
    $$LessonsTableCreateCompanionBuilder,
    $$LessonsTableUpdateCompanionBuilder,
    (Lesson, $$LessonsTableReferences),
    Lesson,
    PrefetchHooks Function(
        {bool subjectId,
        bool classDivisionId,
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
              lessonClassesRefs = false,
              lessonTeachersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
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
                  if (lessonClassesRefs)
                    await $_getPrefetchedData<Lesson, $LessonsTable,
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
                    await $_getPrefetchedData<Lesson, $LessonsTable,
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
    Lesson,
    $$LessonsTableFilterComposer,
    $$LessonsTableOrderingComposer,
    $$LessonsTableAnnotationComposer,
    $$LessonsTableCreateCompanionBuilder,
    $$LessonsTableUpdateCompanionBuilder,
    (Lesson, $$LessonsTableReferences),
    Lesson,
    PrefetchHooks Function(
        {bool subjectId,
        bool classDivisionId,
        bool lessonClassesRefs,
        bool lessonTeachersRefs})>;
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
  ColumnFilters<String> get teacherId => $composableBuilder(
      column: $table.teacherId, builder: (column) => ColumnFilters(column));

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

class $$LessonTeachersTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonTeachersTable> {
  $$LessonTeachersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get teacherId => $composableBuilder(
      column: $table.teacherId, builder: (column) => ColumnOrderings(column));

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

class $$LessonTeachersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonTeachersTable> {
  $$LessonTeachersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get teacherId =>
      $composableBuilder(column: $table.teacherId, builder: (column) => column);

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
    PrefetchHooks Function({bool lessonId})> {
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
                    referencedTable:
                        $$LessonTeachersTableReferences._lessonIdTable(db),
                    referencedColumn:
                        $$LessonTeachersTableReferences._lessonIdTable(db).id,
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
    PrefetchHooks Function({bool lessonId})>;
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
  $$ClassDivisionsTableTableManager get classDivisions =>
      $$ClassDivisionsTableTableManager(_db, _db.classDivisions);
  $$LessonsTableTableManager get lessons =>
      $$LessonsTableTableManager(_db, _db.lessons);
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
