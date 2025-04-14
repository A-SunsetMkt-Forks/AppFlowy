import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/query.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/search_filter.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:nanoid/nanoid.dart';
import 'package:fixnum/fixnum.dart';

class SearchBackendService {
  static Future<FlowyResult<SearchResponseStream, FlowyError>> performSearch(
    String keyword, {
    String? workspaceId,
  }) async {
    final searchId = nanoid(6);
    final stream = SearchResponseStream(searchId: searchId);

    final filter = SearchFilterPB(workspaceId: workspaceId);
    final request = SearchQueryPB(
      search: keyword,
      filter: filter,
      searchId: searchId,
      streamPort: Int64(stream.nativePort),
    );

    unawaited(SearchEventSearch(request).send());
    return FlowyResult.success(stream);
  }
}

class SearchResponseStream {
  SearchResponseStream({required this.searchId}) {
    _port.handler = _controller.add;
    _subscription = _controller.stream.listen(
      (Uint8List data) => _onResultsChanged(data),
    );
  }

  final String searchId;
  final RawReceivePort _port = RawReceivePort();
  final StreamController<Uint8List> _controller = StreamController.broadcast();
  late StreamSubscription<Uint8List> _subscription;
  void Function(
    List<SearchResponseItemPB> items,
    String searchId,
    bool isLoading,
  )? _onItems;
  void Function(
    List<SearchSummaryPB> summaries,
    String searchId,
    bool isLoading,
  )? _onSummaries;
  void Function(String searchId)? _onFinished;
  int get nativePort => _port.sendPort.nativePort;

  Future<void> dispose() async {
    await _subscription.cancel();
    _port.close();
  }

  void _onResultsChanged(Uint8List data) {
    final response = SearchResponsePB.fromBuffer(data);

    if (response.hasResult()) {
      if (response.result.hasSearchResult()) {
        _onItems?.call(
          response.result.searchResult.items,
          searchId,
          response.isLoading,
        );
      }
      if (response.result.hasSearchSummary()) {
        _onSummaries?.call(
          response.result.searchSummary.items,
          searchId,
          response.isLoading,
        );
      }
    } else {
      _onFinished?.call(searchId);
    }
  }

  void listen({
    required void Function(
      List<SearchResponseItemPB> items,
      String searchId,
      bool isLoading,
    )? onItems,
    required void Function(
      List<SearchSummaryPB> summaries,
      String searchId,
      bool isLoading,
    )? onSummaries,
    required void Function(String searchId)? onFinished,
  }) {
    _onItems = onItems;
    _onSummaries = onSummaries;
    _onFinished = onFinished;
  }
}
