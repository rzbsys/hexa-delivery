import 'dart:convert';

import 'package:hexa_delivery/model/dto.dart';
import 'package:hexa_delivery/resources/store_provider.dart';
import 'package:hexa_delivery/utils/user_info_cache.dart';
import 'package:http/http.dart' as http;

class OrderResource {
  // Fields for OrderToBeCreatedDTO
  StoreDTO? storeDTO;
  DateTime expTime = DateTime.now(); // will be updated
  int? fee;
  String? location;
  String? groupLink;

  Future<Iterable<StoreDTO>> getStoreList(String query) async {
    List<StoreDTO> storeList = await StoreListQueryProvider.searchStoresAndGetList(query);

    return storeList;
  }

  Future<bool> createOrder() async {
    int rid = -1;
    if (storeDTO == null || fee == null || location == null || groupLink == null) return false;
    
    if (storeDTO is StoreCreateDTO) {
      StoreCreateDTO storeCreateDTO = storeDTO! as StoreCreateDTO;
      if (storeCreateDTO.category == null) return false;
      rid = await StoreListQueryProvider.createStoreAndGetRID(storeCreateDTO); 
    }
    else { 
      rid = storeDTO!.getRID; 
    }
    print(rid);
    if (rid == -1) return false; // TODO: deal with unexpected error 

    var request = http.MultipartRequest(
        'POST', Uri.parse('http://delivery.hexa.pro/order/create'));

    var headers = {
      "Access-Token": userInfoInMemory.token!,
    };

    var body = {
      "rid": rid.toString(),
      "uid": userInfoInMemory.uid!,
      "exp_time": expTime.toIso8601String(),
      "fee": fee.toString(),
      "location": location!,
      "group_link": groupLink!,
    };

    request.fields.addAll(body);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    var res = await response.stream.bytesToString();

    print(res);
    if (response.statusCode == 201) {
      // If the call to the server was successful, parse the JSON
      Map<String, dynamic> data = json.decode(res)["data"]!;
      
      return true;
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load post');
    }
  }
}
