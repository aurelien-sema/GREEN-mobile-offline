import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/models/scan_result_model.dart';
import 'package:green_app/services/history_service.dart';
import 'package:green_app/services/storage/scan_image_store.dart';
import 'package:green_app/services/user_scope.dart';
import 'package:image/image.dart' as img;

void main() {
  late Directory dir;
  late HistoryService history;
  late ScanImageStore images;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('green_hist_');
    images = ScanImageStore(baseDir: () async => dir);
    history = HistoryService(directory: () async => dir, images: images);
    UserScope.setUserId('u1');
  });
  tearDown(() async {
    UserScope.setUserId(null);
    await dir.delete(recursive: true);
  });

  ScanResultModel scan(String id, DateTime at, {String path = ''}) => ScanResultModel(
        id: id,
        label: 'Corn Healthy',
        diseaseId: 'maize-healthy',
        plantName: 'Maïs',
        diseaseName: 'Maïs sain',
        confidence: 0.9,
        status: ScanStatus.healthy,
        imagePath: path,
        scannedAt: at,
      );

  test('la photo est copiée de façon permanente, réduite et sans EXIF', () async {
    final src = File('${dir.path}/picker_cache.jpg')
      ..writeAsBytesSync(img.encodeJpg(img.Image(width: 4000, height: 3000)));
    final (photo, thumb) = await images.persist(src, 'scan1');
    src.deleteSync(); // Android vide le cache du sélecteur…
    expect(File(photo).existsSync(), isTrue); // …la copie reste.
    final decoded = img.decodeJpg(File(photo).readAsBytesSync())!;
    expect(decoded.width, ScanImageStore.maxSide);
    expect(img.decodeJpg(File(thumb).readAsBytesSync())!.width, ScanImageStore.thumbSide);
    expect(photo, contains('/scans/u1/'));
  });

  test('ordre du plus récent au plus ancien, suppression puis annulation', () async {
    await history.addScan(scan('a', DateTime(2026, 11, 1)));
    await history.addScan(scan('b', DateTime(2026, 11, 5)));
    expect((await history.getAllScans()).map((s) => s.id), ['b', 'a']);
    final removed = await history.removeScan('a');
    expect((await history.getAllScans()).map((s) => s.id), ['b']);
    await history.restoreScan(removed!);
    expect((await history.getAllScans()).map((s) => s.id), ['b', 'a']);
  });

  test('chaque compte a son propre historique', () async {
    await history.addScan(scan('a', DateTime(2026, 11, 1)));
    UserScope.setUserId('u2');
    expect(await history.getAllScans(), isEmpty);
    UserScope.setUserId('u1');
    expect(await history.getAllScans(), hasLength(1));
  });

  test('statistiques', () async {
    await history.addScan(scan('a', DateTime(2026, 11, 1)));
    final stats = await history.statistics();
    expect(stats.total, 1);
    expect(stats.healthy, 1);
  });
}
