import 'package:mongo_dart/mongo_dart.dart';

class DataService {
  static const String _uri =
      'mongodb+srv://ipavaratha_db_user:B2jSmpi7qkVpXuhp@cluster0.f0azxqz.mongodb.net/seettudb?retryWrites=true&w=majority&appName=Cluster0';
  
  static Db? _db;

  static Future<Db> get db async {
    if (_db == null || !_db!.isConnected) {
      _db = await Db.create(_uri);
      await _db!.open();
    }
    return _db!;
  }

  static Future<DbCollection> get _groups async => (await db).collection('groups');
  static Future<DbCollection> get _members async => (await db).collection('members');

  // Helper to map MongoDB _id to string id
  static Map<String, dynamic> _mapId(Map<String, dynamic> doc) {
    if (doc.containsKey('_id')) {
      doc['id'] = (doc['_id'] as ObjectId).toHexString();
      doc.remove('_id');
    }
    return doc;
  }

  // Helper to map string id to MongoDB ObjectId
  static ObjectId _toObjectId(String id) {
    return ObjectId.fromHexString(id);
  }

  // --- GROUPS ---

  static Future<List<Map<String, dynamic>>> getGroups() async {
    final collection = await _groups;
    final docs = await collection.find().toList();
    return docs.map(_mapId).toList();
  }

  static Future<Map<String, dynamic>> getGroupDetails(String groupId) async {
    final collection = await _groups;
    final doc = await collection.findOne(where.id(_toObjectId(groupId)));
    if (doc == null) throw Exception('Group not found');
    return _mapId(doc);
  }

  static Future<void> createGroup(Map<String, dynamic> groupData) async {
    final collection = await _groups;
    final newGroup = Map<String, dynamic>.from(groupData);
    newGroup['_id'] = ObjectId();
    // Default values if not provided
    newGroup['memberCount'] ??= 0;
    newGroup['paidThisMonth'] ??= 0;
    newGroup['nextCollection'] ??= 'TBD';
    await collection.insert(newGroup);
  }

  static Future<void> updateGroup(String id, Map<String, dynamic> updates) async {
    final collection = await _groups;
    var m = modify;
    updates.forEach((key, value) {
      m = m.set(key, value);
    });
    await collection.update(
      where.id(_toObjectId(id)),
      m,
    );
  }

  static Future<void> deleteGroup(String id) async {
    final collection = await _groups;
    await collection.remove(where.id(_toObjectId(id)));
    // Also delete all members of this group
    final membersCollection = await _members;
    await membersCollection.remove(where.eq('groupId', id));
  }

  // --- MEMBERS ---

  static Future<List<Map<String, dynamic>>> getMembersForGroup(String groupId) async {
    final collection = await _members;
    final docs = await collection.find(where.eq('groupId', groupId).sortBy('position')).toList();
    return docs.map(_mapId).toList();
  }

  static Future<Map<String, dynamic>> getMemberDetails(String groupId, String memberId) async {
    final collection = await _members;
    final doc = await collection.findOne(where.id(_toObjectId(memberId)).and(where.eq('groupId', groupId)));
    if (doc == null) throw Exception('Member not found');
    return _mapId(doc);
  }

  static Future<void> createMember(String groupId, Map<String, dynamic> memberData) async {
    final collection = await _members;
    final newMember = Map<String, dynamic>.from(memberData);
    newMember['_id'] = ObjectId();
    newMember['groupId'] = groupId;
    
    // Assign position
    final count = await collection.count(where.eq('groupId', groupId));
    newMember['position'] ??= count + 1;
    newMember['status'] ??= 'Active';
    newMember['nextPayout'] ??= false;

    await collection.insert(newMember);

    // Update group member count
    final groupsCollection = await _groups;
    await groupsCollection.update(
      where.id(_toObjectId(groupId)),
      modify.inc('memberCount', 1),
    );
  }

  static Future<void> updateMember(String groupId, String memberId, Map<String, dynamic> updates) async {
    final collection = await _members;
    var m = modify;
    updates.forEach((key, value) {
      m = m.set(key, value);
    });
    await collection.update(
      where.id(_toObjectId(memberId)),
      m,
    );
  }

  static Future<void> deleteMember(String groupId, String memberId) async {
    final collection = await _members;
    await collection.remove(where.id(_toObjectId(memberId)));

    // Update group member count
    final groupsCollection = await _groups;
    await groupsCollection.update(
      where.id(_toObjectId(groupId)),
      modify.inc('memberCount', -1),
    );
  }
}
