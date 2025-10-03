//
//  Created by Colin Fallon on 15/09/2025.
//

import Foundation
import Crypto
import Logging
import AsyncHTTPClient
import NIOCore
import NIOFoundationCompat

struct Endpoint {
  var queryItems: [URLQueryItem]
}

extension Endpoint {
  // We still have to keep 'url' as an optional, since we're
  // dealing with dynamic components that could be invalid.
  var url: URL? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "www.planyo.com"
    components.path = "/rest/"
    components.queryItems = queryItems
    
    return components.url
  }
}
public struct PlanyoAPI: Sendable {
  let siteId: String
  let apiKey: String
  let hashKey: String
  let logger: Logger
  
  public init(siteId: String, apiKey: String, hashKey: String, logger: Logger) {
    self.siteId = siteId
    self.apiKey = apiKey
    self.hashKey = hashKey
    self.logger = logger
  }
  
 /// Retrieves a list of reservations within the given date range.
 ///
 /// Use this method to fetch multiple reservations from the Planyo API
 /// between a specified start and end date.
 ///
 /// - Parameters:
 ///   - start: The start date in unix time for the reservation query.
 ///   - end: The end date in unix time for the reservation query.
 ///
 /// - Returns: An array of ``Reservation`` objects matching the criteria.
 ///
 /// - Throws: An error if the request fails, the Planyo response cannot be
 ///   decoded, or the Planyo API returns an error status.
 ///
  public func listReservations(start: Int, end: Int) async throws -> [Reservation] {
    var endpoint = Endpoint(queryItems: [])
    endpoint.queryItems.append(URLQueryItem(name: "method", value: "get_reservation_data"))
    endpoint.queryItems.append(URLQueryItem(name: "start_time", value: String(start)))
    endpoint.queryItems.append(URLQueryItem(name: "end_time", value: String(end)))
    endpoint.queryItems.append(URLQueryItem(name: "detail_level", value: "71"))
    let data = try await fetchResource(endpoint: &endpoint)
    let decoder = getJSONDecoder()
    
    var planyoResponse: PlanyoResponse<ListData>
    
    do {
      planyoResponse = try decoder.decode(PlanyoResponse.self, from: data)
    } catch {
      logger.debug("Decode error: \(error)")
      throw PlanyoError.planyoError(message: "Failed to decode planyo json data")
    }
    if planyoResponse.responseCode != 0 {
      throw PlanyoError.planyoError(message: planyoResponse.responseMessage)
    }
    return planyoResponse.data.results

  }
  
  public func getReservation(id: Int) async throws -> Reservation {
    var endpoint = Endpoint(queryItems: [])
    endpoint.queryItems.append(URLQueryItem(name: "method", value: "get_reservation_data"))
    endpoint.queryItems.append(URLQueryItem(name: "reservation_id", value: String(id)))
    let data = try await fetchResource(endpoint: &endpoint)
    logger.debug("Fetched reservation data: \(String(buffer: data))")
    let decoder = getJSONDecoder()
    
    var planyoResponse: PlanyoResponse<Reservation>
    
    do {
      planyoResponse = try decoder.decode(PlanyoResponse.self, from: data)
    } catch {
      logger.debug("Decode error: \(error)")
      throw PlanyoError.planyoError(message: "Failed to decode planyo json data")
    }
    if planyoResponse.responseCode != 0 {
      throw PlanyoError.planyoError(message: planyoResponse.responseMessage)
    }
    
    planyoResponse.data.reservationId = id
    return planyoResponse.data
  }
  
  enum PlanyoError: Error {
    case invalidStatusCode(statusCode: UInt)
    case planyoError(message: String)
  }
  
  private func fetchResource(endpoint: inout Endpoint) async throws -> ByteBuffer {
    endpoint.queryItems.append(URLQueryItem(name: "site_id", value: siteId))
    endpoint.queryItems.append(URLQueryItem(name: "api_key", value: apiKey))
    
    let hashTime = Int(Date().timeIntervalSince1970)
    let method = endpoint.queryItems.first(where: { $0.name == "method" })?.value
    let hashString = "\(hashKey)\(hashTime)\(method ?? "")"
    let hashData = hashString.data(using: .utf8)!
    let digest = Insecure.MD5.hash(data: hashData)
    let hashValue = digest.map { String(format: "%02hhx", $0) }.joined()
    
    endpoint.queryItems.append(URLQueryItem(name: "hash_timestamp", value: String(hashTime)))
    endpoint.queryItems.append(URLQueryItem(name: "hash_key", value: hashValue))
    
    let request = HTTPClientRequest(url: endpoint.url!.absoluteString)
    let response = try await HTTPClient.shared.execute(request, timeout: .seconds(30))
    
    guard response.status == .ok else {
      throw PlanyoError.invalidStatusCode(statusCode: response.status.code)
    }
    
    let body = try await response.body.collect(upTo: 1024 * 1024)
    
    return body
  }
  
  private func getJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    dateFormatter.locale = Locale(identifier: "en_GB")
    dateFormatter.timeZone = TimeZone(identifier: "Europe/London")
    decoder.dateDecodingStrategy = .formatted(dateFormatter)
    return decoder
  }
  
}
