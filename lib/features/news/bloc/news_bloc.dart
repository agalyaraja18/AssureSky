import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/news_article_model.dart';
import '../../../core/services/news_service.dart';

// Events
abstract class NewsEvent {}

class NewsLoadRequested extends NewsEvent {}

class NewsRefreshRequested extends NewsEvent {}

// State
abstract class NewsState {}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsLoaded extends NewsState {
  final List<NewsArticleModel> articles;
  NewsLoaded(this.articles);
}

class NewsError extends NewsState {
  final String message;
  NewsError(this.message);
}

// Bloc
class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsService _service;

  NewsBloc() : _service = NewsService(), super(NewsInitial()) {
    on<NewsLoadRequested>(_onLoad);
    on<NewsRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
      NewsLoadRequested event, Emitter<NewsState> emit) async {
    emit(NewsLoading());
    try {
      final articles = await _service.getWeatherNews();
      emit(NewsLoaded(articles));
    } catch (e) {
      emit(NewsError('Failed to load news. Please try again.'));
    }
  }

  Future<void> _onRefresh(
      NewsRefreshRequested event, Emitter<NewsState> emit) async {
    try {
      final articles = await _service.getWeatherNews();
      emit(NewsLoaded(articles));
    } catch (e) {
      emit(NewsError('Failed to refresh news.'));
    }
  }
}
