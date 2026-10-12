import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() => runApp(const LightMusicApp());

class Track {
  Track({required this.title, required this.artist, required this.album, required this.format, this.path, this.encrypted = false});
  final String title;
  final String artist;
  final String album;
  final String format;
  final String? path;
  final bool encrypted;
}

class LightMusicApp extends StatelessWidget {
  const LightMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '轻听',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff7f8fb),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xfff16b53), brightness: Brightness.light),
        fontFamily: 'Arial',
      ),
      home: const MusicHomePage(),
    );
  }
}

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final _player = AudioPlayer();
  final _searchController = TextEditingController();
  final _tracks = <Track>[
    Track(title: '晚风心里吹', artist: 'Beyond', album: '海阔天空', format: 'MP3'),
    Track(title: '一生所爱', artist: '卢冠廷', album: '大话西游', format: 'FLAC'),
    Track(title: '语音 001', artist: '本地录音', album: '语音文件', format: 'M4A'),
    Track(title: 'To’xta', artist: 'Uzmir', album: '我的收藏', format: 'OGG'),
    Track(title: '心潮', artist: '半根萝卜', album: '本地音乐', format: 'MGG2', encrypted: true),
    Track(title: '从开始到现在', artist: '张信哲', album: '经典现场', format: 'MFLAC0', encrypted: true),
  ];
  int _currentIndex = -1;
  bool _liked = false;
  String _query = '';

  @override
  void dispose() {
    _player.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Track> get _visibleTracks => _tracks.where((track) {
        final text = '${track.title} ${track.artist} ${track.album} ${track.format}'.toLowerCase();
        return text.contains(_query.toLowerCase());
      }).toList();

  Future<void> _importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'flac', 'm4a', 'ogg', 'wav', 'aac', 'mgg', 'mgg1', 'mgg2', 'mflac', 'mflac0'],
    );
    if (result == null) return;
    setState(() {
      for (final file in result.files) {
        final name = file.name;
        final extension = name.split('.').last.toLowerCase();
        final special = name.toLowerCase().contains('mgg') || name.toLowerCase().contains('mflac');
        _tracks.insert(0, Track(
          title: name.replaceFirst(RegExp(r'\.[^.]+$'), ''),
          artist: '本地文件',
          album: '导入的音乐',
          format: special ? (name.toLowerCase().contains('mgg') ? 'MGG2' : 'MFLAC0') : extension.toUpperCase(),
          path: file.path,
          encrypted: special,
        ));
      }
    });
  }

  Future<void> _play(int index) async {
    final track = _tracks[index];
    if (track.encrypted) {
      _message('该文件需要先解密为 FLAC 或 OGG，解密模块将在后续版本加入。');
      return;
    }
    if (track.path == null || !File(track.path!).existsSync()) {
      setState(() => _currentIndex = index);
      _message('这是演示歌曲，请导入本地音频后播放。');
      return;
    }
    await _player.setFilePath(track.path!);
    await _player.play();
    setState(() => _currentIndex = index);
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 760;
    return Scaffold(
      body: SafeArea(
        child: Row(children: [
          if (!isCompact) _buildSidebar(),
          Expanded(child: _buildContent(isCompact)),
        ]),
      ),
      bottomNavigationBar: _buildPlayerBar(isCompact),
    );
  }

  Widget _buildSidebar() => Container(
        width: 230,
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: Color(0xffeceef2)))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _brand(),
          const SizedBox(height: 38),
          _nav(Icons.album_outlined, '全部音乐', true, '128'),
          _nav(Icons.history, '最近播放', false),
          _nav(Icons.favorite_border, '我的收藏', false),
          const SizedBox(height: 32),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('我的歌单', style: TextStyle(fontSize: 11, color: Color(0xffa7aab2), fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          _playlist('通勤路上', const Color(0xfff28a74), '24'),
          _playlist('安静工作', const Color(0xff7e9ff0), '18'),
          _playlist('收藏的现场', const Color(0xffedc269), '36'),
          const Spacer(),
          _textButton(Icons.settings_outlined, '设置'),
          _textButton(Icons.help_outline, '帮助'),
        ]),
      );

  Widget _brand() => const Row(children: [CircleAvatar(radius: 16, backgroundColor: Color(0xff25272e), child: Text('♪', style: TextStyle(color: Colors.white, fontSize: 19))), SizedBox(width: 10), Text('轻听', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))]);

  Widget _nav(IconData icon, String label, bool active, [String? count]) => Container(
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(color: active ? const Color(0xfff1f3f7) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: ListTile(dense: true, visualDensity: VisualDensity.compact, leading: Icon(icon, size: 19, color: active ? const Color(0xfff16b53) : const Color(0xffa1a5ae)), title: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? const Color(0xff24262d) : const Color(0xff888b94))), trailing: count == null ? null : Text(count, style: const TextStyle(fontSize: 11, color: Color(0xffa6a9b1)))))
      );

  Widget _playlist(String label, Color color, String count) => ListTile(dense: true, visualDensity: VisualDensity.compact, contentPadding: const EdgeInsets.symmetric(horizontal: 12), leading: CircleAvatar(radius: 4, backgroundColor: color), title: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xff555861))), trailing: Text(count, style: const TextStyle(fontSize: 11, color: Color(0xffb1b4bc))));
  Widget _textButton(IconData icon, String label) => TextButton.icon(onPressed: () {}, icon: Icon(icon, size: 17), label: Text(label), style: TextButton.styleFrom(foregroundColor: const Color(0xff888b94), alignment: Alignment.centerLeft));

  Widget _buildContent(bool compact) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(compact ? 16 : 54, 18, compact ? 16 : 54, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [if (compact) ...[_brand(), const Spacer()], SizedBox(width: compact ? 42 : 410, child: TextField(controller: _searchController, onChanged: (value) => setState(() => _query = value), decoration: InputDecoration(hintText: '搜索歌曲、歌手或专辑', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none)))), const SizedBox(width: 14), const CircleAvatar(radius: 17, backgroundColor: Color(0xfff4d6cc), child: Text('林', style: TextStyle(color: Color(0xff9c594c), fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 48),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('LOCAL LIBRARY', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, color: Color(0xfff16b53))), const SizedBox(height: 11), Text('全部音乐', style: TextStyle(fontSize: compact ? 34 : 42, letterSpacing: -2, fontWeight: FontWeight.w800)), const SizedBox(height: 7), const Text('你的音乐，只留在你的设备里。', style: TextStyle(fontSize: 13, color: Color(0xff979aa3)))])), FilledButton.icon(onPressed: _importFiles, icon: const Icon(Icons.add, size: 18), label: const Text('导入音乐'), style: FilledButton.styleFrom(backgroundColor: const Color(0xff25272e), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13)))]),
          const SizedBox(height: 30),
          Wrap(spacing: 34, runSpacing: 12, children: const [Stat(value: '128', label: '首歌曲'), Stat(value: '14', label: '张专辑'), Stat(value: '2.12 GB', label: '本地占用')]),
          const SizedBox(height: 25),
          _buildTrackCard(compact),
        ]),
      );

  Widget _buildTrackCard(bool compact) => Card(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xffeaecf1))), clipBehavior: Clip.antiAlias, child: Column(children: [Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18), child: Row(children: [const Text('歌曲', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 24), const Text('专辑', style: TextStyle(color: Color(0xffa1a4ac))), const SizedBox(width: 24), const Text('文件夹', style: TextStyle(color: Color(0xffa1a4ac))), const Spacer(), Text('${_visibleTracks.length} 首', style: const TextStyle(fontSize: 12, color: Color(0xff9699a2)))])), const Divider(height: 1, color: Color(0xfff0f1f4)), ..._visibleTracks.asMap().entries.map((entry) => _trackRow(_tracks.indexOf(entry.value), entry.value, compact))]));

  Widget _trackRow(int index, Track track, bool compact) => InkWell(onTap: () => _play(index), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(colors: track.encrypted ? [const Color(0xfff5aa93), const Color(0xffe85b48)] : [const Color(0xff8aa9f5), const Color(0xff547ce2)])), child: const Icon(Icons.music_note, color: Colors.white, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(track.artist, style: const TextStyle(fontSize: 11, color: Color(0xffa0a3ab)))])), if (!compact) Expanded(child: Text(track.album, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xff8d9099))), flex: 1), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: track.encrypted ? const Color(0xfffff1e9) : const Color(0xfff4f5f7), borderRadius: BorderRadius.circular(5)), child: Text(track.format, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: track.encrypted ? const Color(0xffdc7957) : const Color(0xff858995))), const SizedBox(width: 10), IconButton(onPressed: () => _play(index), icon: Icon(_currentIndex == index ? Icons.pause_circle_filled : Icons.play_circle_outline, color: const Color(0xfff16b53)))]));

  Widget _buildPlayerBar(bool compact) => Container(height: compact ? 142 : 86, padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 34, vertical: 12), decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xffe9ebef))), boxShadow: [BoxShadow(color: Color(0x1020232b), blurRadius: 18, offset: Offset(0, -5))]), child: compact ? Column(children: [_nowPlaying(), const SizedBox(height: 7), _controls()]) : Row(children: [Expanded(child: _nowPlaying()), Expanded(child: _controls()), const SizedBox(width: 160)]));
  Widget _nowPlaying() => Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xfff16b53)), child: const Icon(Icons.music_note, color: Colors.white)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(_currentIndex < 0 ? '还没有播放歌曲' : _tracks[_currentIndex].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(_currentIndex < 0 ? '导入本地音乐开始播放' : _tracks[_currentIndex].artist, style: const TextStyle(fontSize: 11, color: Color(0xffa2a5ad)))])), IconButton(onPressed: () => setState(() => _liked = !_liked), icon: Icon(_liked ? Icons.favorite : Icons.favorite_border, color: _liked ? const Color(0xfff16b53) : const Color(0xff90939c)))]);
  Widget _controls() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(onPressed: () {}, icon: const Icon(Icons.shuffle, size: 18)), IconButton(onPressed: _currentIndex > 0 ? () => _play(_currentIndex - 1) : null, icon: const Icon(Icons.skip_previous)), FilledButton(onPressed: () { if (_currentIndex < 0) _play(0); else if (_player.playing) _player.pause(); else _player.play(); }, style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(12), backgroundColor: const Color(0xfff16b53)), child: Icon(_player.playing ? Icons.pause : Icons.play_arrow, color: Colors.white)), IconButton(onPressed: _currentIndex + 1 < _tracks.length ? () => _play(_currentIndex + 1) : null, icon: const Icon(Icons.skip_next)), IconButton(onPressed: () {}, icon: const Icon(Icons.repeat, size: 18))]);
}

class Stat extends StatelessWidget {
  const Stat({required this.value, required this.label, super.key});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xffa1a4ac)))]);
}
