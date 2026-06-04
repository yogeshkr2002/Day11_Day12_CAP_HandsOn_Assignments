using { my.bookshop as db } from '../db/schema';

/**
 * Public Catalog Service — for browsing books
 */
service CatalogService @(path: '/catalog') {

  // Books: public can browse but not modify
  @readonly entity Books as projection on db.Books {
    ID,
    title,
    genre,
    price,
    stock,
    rating,
    publishDate,
    isbn,
    author     // Include association for $expand
  };

  // Authors: show name and country only (hide email)
  @readonly entity Authors as projection on db.Authors {
    ID,
    name,
    country,
    books      // Include back-navigation
  };

  // Reviews: everyone can read, anyone can create
  @insertonly entity Reviews as projection on db.Reviews;
}