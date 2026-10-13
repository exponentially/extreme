defmodule Extreme.MessagesTest do
  use ExUnit.Case, async: true

  alias Extreme.Messages, as: Msg

  # Encodings and decoded fields captured from exprotobuf 1.2.17, Extreme's encoder up to 1.1.5.
  @messages [
    {:full, Msg.ClientIdentified.new(), "", %{}},
    {:full,
     Msg.ConnectToPersistentSubscription.new(
       subscription_id: "subscription_id-1",
       event_stream_id: "event_stream_id-2",
       allowed_in_flight_messages: 300_009
     ), "0A11737562736372697074696F6E5F69642D3112116576656E745F73747265616D5F69642D3218E9A712",
     %{
       event_stream_id: "event_stream_id-2",
       subscription_id: "subscription_id-1",
       allowed_in_flight_messages: 300_009
     }},
    {:full,
     Msg.CreatePersistentSubscription.new(
       subscription_group_name: "subscription_group_name-1",
       event_stream_id: "event_stream_id-2",
       resolve_link_tos: true,
       start_from: -17_179_869_244,
       message_timeout_milliseconds: 500_015,
       record_statistics: false,
       live_buffer_size: 700_021,
       read_batch_size: -24,
       buffer_size: 900_027,
       max_retry_count: -30,
       prefer_round_robin: true,
       checkpoint_after_time: -36,
       checkpoint_max_count: 1_300_039,
       checkpoint_min_count: -42,
       subscriber_max_count: 1_500_045,
       named_consumer_strategy: "named_consumer_strategy-16"
     ),
     "0A19737562736372697074696F6E5F67726F75705F6E616D652D3112116576656E745F73747265616D5F69642D32180120C4FFFFFFBFFFFFFFFF0128AFC21E300038F5DC2A40E8FFFFFFFFFFFFFFFF0148BBF73650E2FFFFFFFFFFFFFFFF01580160DCFFFFFFFFFFFFFFFF0168C7AC4F70D6FFFFFFFFFFFFFFFF01788DC75B82011A6E616D65645F636F6E73756D65725F73747261746567792D3136",
     %{
       buffer_size: 900_027,
       event_stream_id: "event_stream_id-2",
       resolve_link_tos: true,
       subscription_group_name: "subscription_group_name-1",
       start_from: -17_179_869_244,
       message_timeout_milliseconds: 500_015,
       record_statistics: false,
       live_buffer_size: 700_021,
       read_batch_size: -24,
       max_retry_count: -30,
       prefer_round_robin: true,
       checkpoint_after_time: -36,
       checkpoint_max_count: 1_300_039,
       checkpoint_min_count: -42,
       subscriber_max_count: 1_500_045,
       named_consumer_strategy: "named_consumer_strategy-16"
     }},
    {:minimal,
     Msg.CreatePersistentSubscription.new(
       subscription_group_name: "subscription_group_name-1",
       event_stream_id: "event_stream_id-2",
       resolve_link_tos: true,
       start_from: -17_179_869_244,
       message_timeout_milliseconds: 500_015,
       record_statistics: false,
       live_buffer_size: 700_021,
       read_batch_size: -24,
       buffer_size: 900_027,
       max_retry_count: -30,
       prefer_round_robin: true,
       checkpoint_after_time: -36,
       checkpoint_max_count: 1_300_039,
       checkpoint_min_count: -42,
       subscriber_max_count: 1_500_045
     ),
     "0A19737562736372697074696F6E5F67726F75705F6E616D652D3112116576656E745F73747265616D5F69642D32180120C4FFFFFFBFFFFFFFFF0128AFC21E300038F5DC2A40E8FFFFFFFFFFFFFFFF0148BBF73650E2FFFFFFFFFFFFFFFF01580160DCFFFFFFFFFFFFFFFF0168C7AC4F70D6FFFFFFFFFFFFFFFF01788DC75B",
     %{
       buffer_size: 900_027,
       event_stream_id: "event_stream_id-2",
       resolve_link_tos: true,
       subscription_group_name: "subscription_group_name-1",
       start_from: -17_179_869_244,
       message_timeout_milliseconds: 500_015,
       record_statistics: false,
       live_buffer_size: 700_021,
       read_batch_size: -24,
       max_retry_count: -30,
       prefer_round_robin: true,
       checkpoint_after_time: -36,
       checkpoint_max_count: 1_300_039,
       checkpoint_min_count: -42,
       subscriber_max_count: 1_500_045,
       named_consumer_strategy: nil
     }},
    {:full,
     Msg.CreatePersistentSubscriptionCompleted.new(result: :access_denied, reason: "reason-2"),
     "08031208726561736F6E2D32", %{reason: "reason-2", result: :access_denied}},
    {:minimal, Msg.CreatePersistentSubscriptionCompleted.new(result: :access_denied), "0803",
     %{reason: nil, result: :access_denied}},
    {:full,
     Msg.DeletePersistentSubscription.new(
       subscription_group_name: "subscription_group_name-1",
       event_stream_id: "event_stream_id-2"
     ),
     "0A19737562736372697074696F6E5F67726F75705F6E616D652D3112116576656E745F73747265616D5F69642D32",
     %{event_stream_id: "event_stream_id-2", subscription_group_name: "subscription_group_name-1"}},
    {:full,
     Msg.DeletePersistentSubscriptionCompleted.new(result: :access_denied, reason: "reason-2"),
     "08031208726561736F6E2D32", %{reason: "reason-2", result: :access_denied}},
    {:minimal, Msg.DeletePersistentSubscriptionCompleted.new(result: :access_denied), "0803",
     %{reason: nil, result: :access_denied}},
    {:full,
     Msg.DeleteStream.new(
       event_stream_id: "event_stream_id-1",
       expected_version: -8_589_934_622,
       require_master: true,
       hard_delete: false
     ), "0A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF0118012000",
     %{
       event_stream_id: "event_stream_id-1",
       expected_version: -8_589_934_622,
       require_master: true,
       hard_delete: false
     }},
    {:minimal,
     Msg.DeleteStream.new(
       event_stream_id: "event_stream_id-1",
       expected_version: -8_589_934_622,
       require_master: true
     ), "0A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011801",
     %{
       event_stream_id: "event_stream_id-1",
       expected_version: -8_589_934_622,
       require_master: true,
       hard_delete: nil
     }},
    {:full,
     Msg.DeleteStreamCompleted.new(
       result: :access_denied,
       message: "message-2",
       prepare_position: 12_884_901_933,
       commit_position: -17_179_869_244
     ), "080712096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF01",
     %{
       message: "message-2",
       result: :access_denied,
       commit_position: -17_179_869_244,
       prepare_position: 12_884_901_933
     }},
    {:minimal, Msg.DeleteStreamCompleted.new(result: :access_denied), "0807",
     %{message: nil, result: :access_denied, commit_position: nil, prepare_position: nil}},
    {:full,
     Msg.EventRecord.new(
       event_stream_id: "event_stream_id-1",
       event_number: -8_589_934_622,
       event_id: <<3, 0, 255, 128, 3>>,
       event_type: "event_type-4",
       data_content_type: 500_015,
       metadata_content_type: -18,
       data: <<7, 0, 255, 128, 7>>,
       metadata: <<8, 0, 255, 128, 8>>,
       created: 38_654_705_799,
       created_epoch: -42_949_673_110
     ),
     "0A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF01",
     %{
       data: <<7, 0, 255, 128, 7>>,
       metadata: <<8, 0, 255, 128, 8>>,
       data_content_type: 500_015,
       event_id: <<3, 0, 255, 128, 3>>,
       event_type: "event_type-4",
       metadata_content_type: -18,
       event_stream_id: "event_stream_id-1",
       event_number: -8_589_934_622,
       created: 38_654_705_799,
       created_epoch: -42_949_673_110
     }},
    {:minimal,
     Msg.EventRecord.new(
       event_stream_id: "event_stream_id-1",
       event_number: -8_589_934_622,
       event_id: <<3, 0, 255, 128, 3>>,
       event_type: "event_type-4",
       data_content_type: 500_015,
       metadata_content_type: -18,
       data: <<7, 0, 255, 128, 7>>
     ),
     "0A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF8007",
     %{
       data: <<7, 0, 255, 128, 7>>,
       metadata: nil,
       data_content_type: 500_015,
       event_id: <<3, 0, 255, 128, 3>>,
       event_type: "event_type-4",
       metadata_content_type: -18,
       event_stream_id: "event_stream_id-1",
       event_number: -8_589_934_622,
       created: nil,
       created_epoch: nil
     }},
    {:full, Msg.IdentifyClient.new(version: 100_003, connection_name: "connection_name-2"),
     "08A38D061211636F6E6E656374696F6E5F6E616D652D32",
     %{version: 100_003, connection_name: "connection_name-2"}},
    {:minimal, Msg.IdentifyClient.new(version: 100_003), "08A38D06",
     %{version: 100_003, connection_name: nil}},
    {:full,
     Msg.NewEvent.new(
       event_id: <<1, 0, 255, 128, 1>>,
       event_type: "event_type-2",
       data_content_type: 300_009,
       metadata_content_type: -12,
       data: <<5, 0, 255, 128, 5>>,
       metadata: <<6, 0, 255, 128, 6>>
     ),
     "0A050100FF8001120C6576656E745F747970652D3218E9A71220F4FFFFFFFFFFFFFFFF012A050500FF800532050600FF8006",
     %{
       data: <<5, 0, 255, 128, 5>>,
       metadata: <<6, 0, 255, 128, 6>>,
       data_content_type: 300_009,
       event_id: <<1, 0, 255, 128, 1>>,
       event_type: "event_type-2",
       metadata_content_type: -12
     }},
    {:minimal,
     Msg.NewEvent.new(
       event_id: <<1, 0, 255, 128, 1>>,
       event_type: "event_type-2",
       data_content_type: 300_009,
       metadata_content_type: -12,
       data: <<5, 0, 255, 128, 5>>
     ), "0A050100FF8001120C6576656E745F747970652D3218E9A71220F4FFFFFFFFFFFFFFFF012A050500FF8005",
     %{
       data: <<5, 0, 255, 128, 5>>,
       metadata: nil,
       data_content_type: 300_009,
       event_id: <<1, 0, 255, 128, 1>>,
       event_type: "event_type-2",
       metadata_content_type: -12
     }},
    {:full, Msg.NotHandled.new(reason: :not_master, additional_info: <<2, 0, 255, 128, 2>>),
     "080212050200FF8002", %{reason: :not_master, additional_info: <<2, 0, 255, 128, 2>>}},
    {:minimal, Msg.NotHandled.new(reason: :not_master), "0802",
     %{reason: :not_master, additional_info: nil}},
    {:full,
     Msg.NotHandled.MasterInfo.new(
       external_tcp_address: "external_tcp_address-1",
       external_tcp_port: -6,
       external_http_address: "external_http_address-3",
       external_http_port: -12,
       external_secure_tcp_address: "external_secure_tcp_address-5",
       external_secure_tcp_port: -18
     ),
     "0A1665787465726E616C5F7463705F616464726573732D3110FAFFFFFFFFFFFFFFFF011A1765787465726E616C5F687474705F616464726573732D3320F4FFFFFFFFFFFFFFFF012A1D65787465726E616C5F7365637572655F7463705F616464726573732D3530EEFFFFFFFFFFFFFFFF01",
     %{
       external_tcp_address: "external_tcp_address-1",
       external_tcp_port: -6,
       external_http_address: "external_http_address-3",
       external_http_port: -12,
       external_secure_tcp_address: "external_secure_tcp_address-5",
       external_secure_tcp_port: -18
     }},
    {:minimal,
     Msg.NotHandled.MasterInfo.new(
       external_tcp_address: "external_tcp_address-1",
       external_tcp_port: -6,
       external_http_address: "external_http_address-3",
       external_http_port: -12
     ),
     "0A1665787465726E616C5F7463705F616464726573732D3110FAFFFFFFFFFFFFFFFF011A1765787465726E616C5F687474705F616464726573732D3320F4FFFFFFFFFFFFFFFF01",
     %{
       external_tcp_address: "external_tcp_address-1",
       external_tcp_port: -6,
       external_http_address: "external_http_address-3",
       external_http_port: -12,
       external_secure_tcp_address: nil,
       external_secure_tcp_port: nil
     }},
    {:full,
     Msg.PersistentSubscriptionAckEvents.new(
       subscription_id: "subscription_id-1",
       processed_event_ids: [<<2, 0, 255, 128, 2>>, <<2, 0, 255, 128, 2>>]
     ), "0A11737562736372697074696F6E5F69642D3112050200FF800212050200FF8002",
     %{
       subscription_id: "subscription_id-1",
       processed_event_ids: [<<2, 0, 255, 128, 2>>, <<2, 0, 255, 128, 2>>]
     }},
    {:minimal, Msg.PersistentSubscriptionAckEvents.new(subscription_id: "subscription_id-1"),
     "0A11737562736372697074696F6E5F69642D31",
     %{subscription_id: "subscription_id-1", processed_event_ids: []}},
    {:full,
     Msg.PersistentSubscriptionConfirmation.new(
       last_commit_position: 4_294_967_311,
       subscription_id: "subscription_id-2",
       last_event_number: 12_884_901_933
     ), "088F808080101211737562736372697074696F6E5F69642D3218AD80808030",
     %{
       last_event_number: 12_884_901_933,
       last_commit_position: 4_294_967_311,
       subscription_id: "subscription_id-2"
     }},
    {:minimal,
     Msg.PersistentSubscriptionConfirmation.new(
       last_commit_position: 4_294_967_311,
       subscription_id: "subscription_id-2"
     ), "088F808080101211737562736372697074696F6E5F69642D32",
     %{
       last_event_number: nil,
       last_commit_position: 4_294_967_311,
       subscription_id: "subscription_id-2"
     }},
    {:full,
     Msg.PersistentSubscriptionNakEvents.new(
       subscription_id: "subscription_id-1",
       processed_event_ids: [<<2, 0, 255, 128, 2>>, <<2, 0, 255, 128, 2>>],
       message: "message-3",
       action: :stop
     ),
     "0A11737562736372697074696F6E5F69642D3112050200FF800212050200FF80021A096D6573736167652D332004",
     %{
       message: "message-3",
       action: :stop,
       subscription_id: "subscription_id-1",
       processed_event_ids: [<<2, 0, 255, 128, 2>>, <<2, 0, 255, 128, 2>>]
     }},
    {:minimal,
     Msg.PersistentSubscriptionNakEvents.new(subscription_id: "subscription_id-1", action: :stop),
     "0A11737562736372697074696F6E5F69642D312004",
     %{message: nil, action: :stop, subscription_id: "subscription_id-1", processed_event_ids: []}},
    {:full,
     Msg.PersistentSubscriptionStreamEventAppeared.new(
       event:
         Msg.ResolvedIndexedEvent.new(
           event:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             ),
           link:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             )
         ),
       retryCount: -6
     ),
     "0AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0110FAFFFFFFFFFFFFFFFF01",
     %{
       event: %{
         link: %{
           data: <<7, 0, 255, 128, 7>>,
           metadata: <<8, 0, 255, 128, 8>>,
           data_content_type: 500_015,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           metadata_content_type: -18,
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           created: 38_654_705_799,
           created_epoch: -42_949_673_110
         },
         event: %{
           data: <<7, 0, 255, 128, 7>>,
           metadata: <<8, 0, 255, 128, 8>>,
           data_content_type: 500_015,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           metadata_content_type: -18,
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           created: 38_654_705_799,
           created_epoch: -42_949_673_110
         }
       },
       retryCount: -6
     }},
    {:minimal,
     Msg.PersistentSubscriptionStreamEventAppeared.new(
       event:
         Msg.ResolvedIndexedEvent.new(
           event:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>
             )
         )
     ),
     "0A4B0A490A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF8007",
     %{
       event: %{
         link: nil,
         event: %{
           data: <<7, 0, 255, 128, 7>>,
           metadata: nil,
           data_content_type: 500_015,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           metadata_content_type: -18,
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           created: nil,
           created_epoch: nil
         }
       },
       retryCount: nil
     }},
    {:full,
     Msg.ReadAllEvents.new(
       commit_position: 4_294_967_311,
       prepare_position: -8_589_934_622,
       max_count: 300_009,
       resolve_link_tos: false,
       require_master: true
     ), "088F8080801010E2FFFFFFDFFFFFFFFF0118E9A71220002801",
     %{
       commit_position: 4_294_967_311,
       prepare_position: -8_589_934_622,
       require_master: true,
       resolve_link_tos: false,
       max_count: 300_009
     }},
    {:full,
     Msg.ReadAllEventsCompleted.new(
       commit_position: 4_294_967_311,
       prepare_position: -8_589_934_622,
       events: [
         Msg.ResolvedEvent.new(
           event:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             ),
           link:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             ),
           commit_position: 12_884_901_933,
           prepare_position: -17_179_869_244
         ),
         Msg.ResolvedEvent.new(
           event:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             ),
           link:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             ),
           commit_position: 12_884_901_933,
           prepare_position: -17_179_869_244
         )
       ],
       next_commit_position: -17_179_869_244,
       next_prepare_position: 21_474_836_555,
       result: :access_denied,
       error: "error-7"
     ),
     "088F8080801010E2FFFFFFDFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF0120C4FFFFFFBFFFFFFFFF0128CB8080805030033A076572726F722D37",
     %{
       error: "error-7",
       events: [
         %{
           link: %{
             data: <<7, 0, 255, 128, 7>>,
             metadata: <<8, 0, 255, 128, 8>>,
             data_content_type: 500_015,
             event_id: <<3, 0, 255, 128, 3>>,
             event_type: "event_type-4",
             metadata_content_type: -18,
             event_stream_id: "event_stream_id-1",
             event_number: -8_589_934_622,
             created: 38_654_705_799,
             created_epoch: -42_949_673_110
           },
           event: %{
             data: <<7, 0, 255, 128, 7>>,
             metadata: <<8, 0, 255, 128, 8>>,
             data_content_type: 500_015,
             event_id: <<3, 0, 255, 128, 3>>,
             event_type: "event_type-4",
             metadata_content_type: -18,
             event_stream_id: "event_stream_id-1",
             event_number: -8_589_934_622,
             created: 38_654_705_799,
             created_epoch: -42_949_673_110
           },
           commit_position: 12_884_901_933,
           prepare_position: -17_179_869_244
         },
         %{
           link: %{
             data: <<7, 0, 255, 128, 7>>,
             metadata: <<8, 0, 255, 128, 8>>,
             data_content_type: 500_015,
             event_id: <<3, 0, 255, 128, 3>>,
             event_type: "event_type-4",
             metadata_content_type: -18,
             event_stream_id: "event_stream_id-1",
             event_number: -8_589_934_622,
             created: 38_654_705_799,
             created_epoch: -42_949_673_110
           },
           event: %{
             data: <<7, 0, 255, 128, 7>>,
             metadata: <<8, 0, 255, 128, 8>>,
             data_content_type: 500_015,
             event_id: <<3, 0, 255, 128, 3>>,
             event_type: "event_type-4",
             metadata_content_type: -18,
             event_stream_id: "event_stream_id-1",
             event_number: -8_589_934_622,
             created: 38_654_705_799,
             created_epoch: -42_949_673_110
           },
           commit_position: 12_884_901_933,
           prepare_position: -17_179_869_244
         }
       ],
       result: :access_denied,
       commit_position: 4_294_967_311,
       prepare_position: -8_589_934_622,
       next_commit_position: -17_179_869_244,
       next_prepare_position: 21_474_836_555
     }},
    {:minimal,
     Msg.ReadAllEventsCompleted.new(
       commit_position: 4_294_967_311,
       prepare_position: -8_589_934_622,
       next_commit_position: -17_179_869_244,
       next_prepare_position: 21_474_836_555
     ), "088F8080801010E2FFFFFFDFFFFFFFFF0120C4FFFFFFBFFFFFFFFF0128CB808080503000",
     %{
       error: nil,
       events: [],
       result: :success,
       commit_position: 4_294_967_311,
       prepare_position: -8_589_934_622,
       next_commit_position: -17_179_869_244,
       next_prepare_position: 21_474_836_555
     }},
    {:full,
     Msg.ReadEvent.new(
       event_stream_id: "event_stream_id-1",
       event_number: -8_589_934_622,
       resolve_link_tos: true,
       require_master: false
     ), "0A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF0118012000",
     %{
       event_stream_id: "event_stream_id-1",
       event_number: -8_589_934_622,
       require_master: false,
       resolve_link_tos: true
     }},
    {:full,
     Msg.ReadEventCompleted.new(
       result: :access_denied,
       event:
         Msg.ResolvedIndexedEvent.new(
           event:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             ),
           link:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             )
         ),
       error: "error-3"
     ),
     "080512C8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF011A076572726F722D33",
     %{
       error: "error-3",
       result: :access_denied,
       event: %{
         link: %{
           data: <<7, 0, 255, 128, 7>>,
           metadata: <<8, 0, 255, 128, 8>>,
           data_content_type: 500_015,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           metadata_content_type: -18,
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           created: 38_654_705_799,
           created_epoch: -42_949_673_110
         },
         event: %{
           data: <<7, 0, 255, 128, 7>>,
           metadata: <<8, 0, 255, 128, 8>>,
           data_content_type: 500_015,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           metadata_content_type: -18,
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           created: 38_654_705_799,
           created_epoch: -42_949_673_110
         }
       }
     }},
    {:minimal,
     Msg.ReadEventCompleted.new(
       result: :access_denied,
       event:
         Msg.ResolvedIndexedEvent.new(
           event:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>
             )
         )
     ),
     "0805124B0A490A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF8007",
     %{
       error: nil,
       result: :access_denied,
       event: %{
         link: nil,
         event: %{
           data: <<7, 0, 255, 128, 7>>,
           metadata: nil,
           data_content_type: 500_015,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           metadata_content_type: -18,
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           created: nil,
           created_epoch: nil
         }
       }
     }},
    {:full,
     Msg.ReadStreamEvents.new(
       event_stream_id: "event_stream_id-1",
       from_event_number: -8_589_934_622,
       max_count: 300_009,
       resolve_link_tos: false,
       require_master: true
     ), "0A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF0118E9A71220002801",
     %{
       event_stream_id: "event_stream_id-1",
       require_master: true,
       resolve_link_tos: false,
       from_event_number: -8_589_934_622,
       max_count: 300_009
     }},
    {:full,
     Msg.ReadStreamEventsBackward.new(
       event_stream_id: "event_stream_id-1",
       from_event_number: -8_589_934_622,
       max_count: 300_009,
       resolve_link_tos: false,
       require_master: true
     ), "0A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF0118E9A71220002801",
     %{
       event_stream_id: "event_stream_id-1",
       require_master: true,
       resolve_link_tos: false,
       from_event_number: -8_589_934_622,
       max_count: 300_009
     }},
    {:full,
     Msg.ReadStreamEventsCompleted.new(
       events: [
         Msg.ResolvedIndexedEvent.new(
           event:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             ),
           link:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             )
         ),
         Msg.ResolvedIndexedEvent.new(
           event:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             ),
           link:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             )
         )
       ],
       result: :access_denied,
       next_event_number: 12_884_901_933,
       last_event_number: -17_179_869_244,
       is_end_of_stream: true,
       last_commit_position: -25_769_803_866,
       error: "error-7"
     ),
     "0AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF010AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF01100518AD8080803020C4FFFFFFBFFFFFFFFF01280130A6FFFFFF9FFFFFFFFF013A076572726F722D37",
     %{
       error: "error-7",
       events: [
         %{
           link: %{
             data: <<7, 0, 255, 128, 7>>,
             metadata: <<8, 0, 255, 128, 8>>,
             data_content_type: 500_015,
             event_id: <<3, 0, 255, 128, 3>>,
             event_type: "event_type-4",
             metadata_content_type: -18,
             event_stream_id: "event_stream_id-1",
             event_number: -8_589_934_622,
             created: 38_654_705_799,
             created_epoch: -42_949_673_110
           },
           event: %{
             data: <<7, 0, 255, 128, 7>>,
             metadata: <<8, 0, 255, 128, 8>>,
             data_content_type: 500_015,
             event_id: <<3, 0, 255, 128, 3>>,
             event_type: "event_type-4",
             metadata_content_type: -18,
             event_stream_id: "event_stream_id-1",
             event_number: -8_589_934_622,
             created: 38_654_705_799,
             created_epoch: -42_949_673_110
           }
         },
         %{
           link: %{
             data: <<7, 0, 255, 128, 7>>,
             metadata: <<8, 0, 255, 128, 8>>,
             data_content_type: 500_015,
             event_id: <<3, 0, 255, 128, 3>>,
             event_type: "event_type-4",
             metadata_content_type: -18,
             event_stream_id: "event_stream_id-1",
             event_number: -8_589_934_622,
             created: 38_654_705_799,
             created_epoch: -42_949_673_110
           },
           event: %{
             data: <<7, 0, 255, 128, 7>>,
             metadata: <<8, 0, 255, 128, 8>>,
             data_content_type: 500_015,
             event_id: <<3, 0, 255, 128, 3>>,
             event_type: "event_type-4",
             metadata_content_type: -18,
             event_stream_id: "event_stream_id-1",
             event_number: -8_589_934_622,
             created: 38_654_705_799,
             created_epoch: -42_949_673_110
           }
         }
       ],
       result: :access_denied,
       last_event_number: -17_179_869_244,
       next_event_number: 12_884_901_933,
       is_end_of_stream: true,
       last_commit_position: -25_769_803_866
     }},
    {:minimal,
     Msg.ReadStreamEventsCompleted.new(
       result: :access_denied,
       next_event_number: 12_884_901_933,
       last_event_number: -17_179_869_244,
       is_end_of_stream: true,
       last_commit_position: -25_769_803_866
     ), "100518AD8080803020C4FFFFFFBFFFFFFFFF01280130A6FFFFFF9FFFFFFFFF01",
     %{
       error: nil,
       events: [],
       result: :access_denied,
       last_event_number: -17_179_869_244,
       next_event_number: 12_884_901_933,
       is_end_of_stream: true,
       last_commit_position: -25_769_803_866
     }},
    {:full,
     Msg.ResolvedEvent.new(
       event:
         Msg.EventRecord.new(
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           data_content_type: 500_015,
           metadata_content_type: -18,
           data: <<7, 0, 255, 128, 7>>,
           metadata: <<8, 0, 255, 128, 8>>,
           created: 38_654_705_799,
           created_epoch: -42_949_673_110
         ),
       link:
         Msg.EventRecord.new(
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           data_content_type: 500_015,
           metadata_content_type: -18,
           data: <<7, 0, 255, 128, 7>>,
           metadata: <<8, 0, 255, 128, 8>>,
           created: 38_654_705_799,
           created_epoch: -42_949_673_110
         ),
       commit_position: 12_884_901_933,
       prepare_position: -17_179_869_244
     ),
     "0A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF01",
     %{
       link: %{
         data: <<7, 0, 255, 128, 7>>,
         metadata: <<8, 0, 255, 128, 8>>,
         data_content_type: 500_015,
         event_id: <<3, 0, 255, 128, 3>>,
         event_type: "event_type-4",
         metadata_content_type: -18,
         event_stream_id: "event_stream_id-1",
         event_number: -8_589_934_622,
         created: 38_654_705_799,
         created_epoch: -42_949_673_110
       },
       event: %{
         data: <<7, 0, 255, 128, 7>>,
         metadata: <<8, 0, 255, 128, 8>>,
         data_content_type: 500_015,
         event_id: <<3, 0, 255, 128, 3>>,
         event_type: "event_type-4",
         metadata_content_type: -18,
         event_stream_id: "event_stream_id-1",
         event_number: -8_589_934_622,
         created: 38_654_705_799,
         created_epoch: -42_949_673_110
       },
       commit_position: 12_884_901_933,
       prepare_position: -17_179_869_244
     }},
    {:minimal,
     Msg.ResolvedEvent.new(
       event:
         Msg.EventRecord.new(
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           data_content_type: 500_015,
           metadata_content_type: -18,
           data: <<7, 0, 255, 128, 7>>
         ),
       commit_position: 12_884_901_933,
       prepare_position: -17_179_869_244
     ),
     "0A490A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800718AD8080803020C4FFFFFFBFFFFFFFFF01",
     %{
       link: nil,
       event: %{
         data: <<7, 0, 255, 128, 7>>,
         metadata: nil,
         data_content_type: 500_015,
         event_id: <<3, 0, 255, 128, 3>>,
         event_type: "event_type-4",
         metadata_content_type: -18,
         event_stream_id: "event_stream_id-1",
         event_number: -8_589_934_622,
         created: nil,
         created_epoch: nil
       },
       commit_position: 12_884_901_933,
       prepare_position: -17_179_869_244
     }},
    {:full,
     Msg.ResolvedIndexedEvent.new(
       event:
         Msg.EventRecord.new(
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           data_content_type: 500_015,
           metadata_content_type: -18,
           data: <<7, 0, 255, 128, 7>>,
           metadata: <<8, 0, 255, 128, 8>>,
           created: 38_654_705_799,
           created_epoch: -42_949_673_110
         ),
       link:
         Msg.EventRecord.new(
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           data_content_type: 500_015,
           metadata_content_type: -18,
           data: <<7, 0, 255, 128, 7>>,
           metadata: <<8, 0, 255, 128, 8>>,
           created: 38_654_705_799,
           created_epoch: -42_949_673_110
         )
     ),
     "0A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF01",
     %{
       link: %{
         data: <<7, 0, 255, 128, 7>>,
         metadata: <<8, 0, 255, 128, 8>>,
         data_content_type: 500_015,
         event_id: <<3, 0, 255, 128, 3>>,
         event_type: "event_type-4",
         metadata_content_type: -18,
         event_stream_id: "event_stream_id-1",
         event_number: -8_589_934_622,
         created: 38_654_705_799,
         created_epoch: -42_949_673_110
       },
       event: %{
         data: <<7, 0, 255, 128, 7>>,
         metadata: <<8, 0, 255, 128, 8>>,
         data_content_type: 500_015,
         event_id: <<3, 0, 255, 128, 3>>,
         event_type: "event_type-4",
         metadata_content_type: -18,
         event_stream_id: "event_stream_id-1",
         event_number: -8_589_934_622,
         created: 38_654_705_799,
         created_epoch: -42_949_673_110
       }
     }},
    {:minimal,
     Msg.ResolvedIndexedEvent.new(
       event:
         Msg.EventRecord.new(
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           data_content_type: 500_015,
           metadata_content_type: -18,
           data: <<7, 0, 255, 128, 7>>
         )
     ),
     "0A490A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF8007",
     %{
       link: nil,
       event: %{
         data: <<7, 0, 255, 128, 7>>,
         metadata: nil,
         data_content_type: 500_015,
         event_id: <<3, 0, 255, 128, 3>>,
         event_type: "event_type-4",
         metadata_content_type: -18,
         event_stream_id: "event_stream_id-1",
         event_number: -8_589_934_622,
         created: nil,
         created_epoch: nil
       }
     }},
    {:full, Msg.ScavengeDatabase.new(), "", %{}},
    {:full,
     Msg.ScavengeDatabaseCompleted.new(
       result: :failed,
       error: "error-2",
       total_time_ms: 300_009,
       total_space_saved: -17_179_869_244
     ), "080212076572726F722D3218E9A71220C4FFFFFFBFFFFFFFFF01",
     %{
       error: "error-2",
       result: :failed,
       total_time_ms: 300_009,
       total_space_saved: -17_179_869_244
     }},
    {:minimal,
     Msg.ScavengeDatabaseCompleted.new(
       result: :failed,
       total_time_ms: 300_009,
       total_space_saved: -17_179_869_244
     ), "080218E9A71220C4FFFFFFBFFFFFFFFF01",
     %{error: nil, result: :failed, total_time_ms: 300_009, total_space_saved: -17_179_869_244}},
    {:full,
     Msg.StreamEventAppeared.new(
       event:
         Msg.ResolvedEvent.new(
           event:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             ),
           link:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>,
               metadata: <<8, 0, 255, 128, 8>>,
               created: 38_654_705_799,
               created_epoch: -42_949_673_110
             ),
           commit_position: 12_884_901_933,
           prepare_position: -17_179_869_244
         )
     ),
     "0AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF01",
     %{
       event: %{
         link: %{
           data: <<7, 0, 255, 128, 7>>,
           metadata: <<8, 0, 255, 128, 8>>,
           data_content_type: 500_015,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           metadata_content_type: -18,
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           created: 38_654_705_799,
           created_epoch: -42_949_673_110
         },
         event: %{
           data: <<7, 0, 255, 128, 7>>,
           metadata: <<8, 0, 255, 128, 8>>,
           data_content_type: 500_015,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           metadata_content_type: -18,
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           created: 38_654_705_799,
           created_epoch: -42_949_673_110
         },
         commit_position: 12_884_901_933,
         prepare_position: -17_179_869_244
       }
     }},
    {:minimal,
     Msg.StreamEventAppeared.new(
       event:
         Msg.ResolvedEvent.new(
           event:
             Msg.EventRecord.new(
               event_stream_id: "event_stream_id-1",
               event_number: -8_589_934_622,
               event_id: <<3, 0, 255, 128, 3>>,
               event_type: "event_type-4",
               data_content_type: 500_015,
               metadata_content_type: -18,
               data: <<7, 0, 255, 128, 7>>
             ),
           commit_position: 12_884_901_933,
           prepare_position: -17_179_869_244
         )
     ),
     "0A5C0A490A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800718AD8080803020C4FFFFFFBFFFFFFFFF01",
     %{
       event: %{
         link: nil,
         event: %{
           data: <<7, 0, 255, 128, 7>>,
           metadata: nil,
           data_content_type: 500_015,
           event_id: <<3, 0, 255, 128, 3>>,
           event_type: "event_type-4",
           metadata_content_type: -18,
           event_stream_id: "event_stream_id-1",
           event_number: -8_589_934_622,
           created: nil,
           created_epoch: nil
         },
         commit_position: 12_884_901_933,
         prepare_position: -17_179_869_244
       }
     }},
    {:full,
     Msg.SubscribeToStream.new(event_stream_id: "event_stream_id-1", resolve_link_tos: false),
     "0A116576656E745F73747265616D5F69642D311000",
     %{event_stream_id: "event_stream_id-1", resolve_link_tos: false}},
    {:full,
     Msg.SubscriptionConfirmation.new(
       last_commit_position: 4_294_967_311,
       last_event_number: -8_589_934_622
     ), "088F8080801010E2FFFFFFDFFFFFFFFF01",
     %{last_event_number: -8_589_934_622, last_commit_position: 4_294_967_311}},
    {:minimal, Msg.SubscriptionConfirmation.new(last_commit_position: 4_294_967_311),
     "088F80808010", %{last_event_number: nil, last_commit_position: 4_294_967_311}},
    {:full, Msg.SubscriptionDropped.new(reason: :subscriber_max_count_reached), "0804",
     %{reason: :subscriber_max_count_reached}},
    {:minimal, Msg.SubscriptionDropped.new(), "0800", %{reason: :unsubscribed}},
    {:full, Msg.TransactionCommit.new(transaction_id: 4_294_967_311, require_master: false),
     "088F808080101000", %{require_master: false, transaction_id: 4_294_967_311}},
    {:full,
     Msg.TransactionCommitCompleted.new(
       transaction_id: 4_294_967_311,
       result: :access_denied,
       message: "message-3",
       first_event_number: -17_179_869_244,
       last_event_number: 21_474_836_555,
       prepare_position: -25_769_803_866,
       commit_position: 30_064_771_177
     ),
     "088F8080801010071A096D6573736167652D3320C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070",
     %{
       message: "message-3",
       result: :access_denied,
       commit_position: 30_064_771_177,
       prepare_position: -25_769_803_866,
       first_event_number: -17_179_869_244,
       last_event_number: 21_474_836_555,
       transaction_id: 4_294_967_311
     }},
    {:minimal,
     Msg.TransactionCommitCompleted.new(
       transaction_id: 4_294_967_311,
       result: :access_denied,
       first_event_number: -17_179_869_244,
       last_event_number: 21_474_836_555
     ), "088F80808010100720C4FFFFFFBFFFFFFFFF0128CB80808050",
     %{
       message: nil,
       result: :access_denied,
       commit_position: nil,
       prepare_position: nil,
       first_event_number: -17_179_869_244,
       last_event_number: 21_474_836_555,
       transaction_id: 4_294_967_311
     }},
    {:full,
     Msg.TransactionStart.new(
       event_stream_id: "event_stream_id-1",
       expected_version: -8_589_934_622,
       require_master: true
     ), "0A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011801",
     %{
       event_stream_id: "event_stream_id-1",
       expected_version: -8_589_934_622,
       require_master: true
     }},
    {:full,
     Msg.TransactionStartCompleted.new(
       transaction_id: 4_294_967_311,
       result: :access_denied,
       message: "message-3"
     ), "088F8080801010071A096D6573736167652D33",
     %{message: "message-3", result: :access_denied, transaction_id: 4_294_967_311}},
    {:minimal,
     Msg.TransactionStartCompleted.new(transaction_id: 4_294_967_311, result: :access_denied),
     "088F808080101007", %{message: nil, result: :access_denied, transaction_id: 4_294_967_311}},
    {:full,
     Msg.TransactionWrite.new(
       transaction_id: 4_294_967_311,
       events: [
         Msg.NewEvent.new(
           event_id: <<1, 0, 255, 128, 1>>,
           event_type: "event_type-2",
           data_content_type: 300_009,
           metadata_content_type: -12,
           data: <<5, 0, 255, 128, 5>>,
           metadata: <<6, 0, 255, 128, 6>>
         ),
         Msg.NewEvent.new(
           event_id: <<1, 0, 255, 128, 1>>,
           event_type: "event_type-2",
           data_content_type: 300_009,
           metadata_content_type: -12,
           data: <<5, 0, 255, 128, 5>>,
           metadata: <<6, 0, 255, 128, 6>>
         )
       ],
       require_master: true
     ),
     "088F8080801012320A050100FF8001120C6576656E745F747970652D3218E9A71220F4FFFFFFFFFFFFFFFF012A050500FF800532050600FF800612320A050100FF8001120C6576656E745F747970652D3218E9A71220F4FFFFFFFFFFFFFFFF012A050500FF800532050600FF80061801",
     %{
       events: [
         %{
           data: <<5, 0, 255, 128, 5>>,
           metadata: <<6, 0, 255, 128, 6>>,
           data_content_type: 300_009,
           event_id: <<1, 0, 255, 128, 1>>,
           event_type: "event_type-2",
           metadata_content_type: -12
         },
         %{
           data: <<5, 0, 255, 128, 5>>,
           metadata: <<6, 0, 255, 128, 6>>,
           data_content_type: 300_009,
           event_id: <<1, 0, 255, 128, 1>>,
           event_type: "event_type-2",
           metadata_content_type: -12
         }
       ],
       require_master: true,
       transaction_id: 4_294_967_311
     }},
    {:minimal, Msg.TransactionWrite.new(transaction_id: 4_294_967_311, require_master: true),
     "088F808080101801", %{events: [], require_master: true, transaction_id: 4_294_967_311}},
    {:full,
     Msg.TransactionWriteCompleted.new(
       transaction_id: 4_294_967_311,
       result: :access_denied,
       message: "message-3"
     ), "088F8080801010071A096D6573736167652D33",
     %{message: "message-3", result: :access_denied, transaction_id: 4_294_967_311}},
    {:minimal,
     Msg.TransactionWriteCompleted.new(transaction_id: 4_294_967_311, result: :access_denied),
     "088F808080101007", %{message: nil, result: :access_denied, transaction_id: 4_294_967_311}},
    {:full, Msg.UnsubscribeFromStream.new(), "", %{}},
    {:full,
     Msg.UpdatePersistentSubscription.new(
       subscription_group_name: "subscription_group_name-1",
       event_stream_id: "event_stream_id-2",
       resolve_link_tos: true,
       start_from: -17_179_869_244,
       message_timeout_milliseconds: 500_015,
       record_statistics: false,
       live_buffer_size: 700_021,
       read_batch_size: -24,
       buffer_size: 900_027,
       max_retry_count: -30,
       prefer_round_robin: true,
       checkpoint_after_time: -36,
       checkpoint_max_count: 1_300_039,
       checkpoint_min_count: -42,
       subscriber_max_count: 1_500_045,
       named_consumer_strategy: "named_consumer_strategy-16"
     ),
     "0A19737562736372697074696F6E5F67726F75705F6E616D652D3112116576656E745F73747265616D5F69642D32180120C4FFFFFFBFFFFFFFFF0128AFC21E300038F5DC2A40E8FFFFFFFFFFFFFFFF0148BBF73650E2FFFFFFFFFFFFFFFF01580160DCFFFFFFFFFFFFFFFF0168C7AC4F70D6FFFFFFFFFFFFFFFF01788DC75B82011A6E616D65645F636F6E73756D65725F73747261746567792D3136",
     %{
       buffer_size: 900_027,
       event_stream_id: "event_stream_id-2",
       resolve_link_tos: true,
       subscription_group_name: "subscription_group_name-1",
       start_from: -17_179_869_244,
       message_timeout_milliseconds: 500_015,
       record_statistics: false,
       live_buffer_size: 700_021,
       read_batch_size: -24,
       max_retry_count: -30,
       prefer_round_robin: true,
       checkpoint_after_time: -36,
       checkpoint_max_count: 1_300_039,
       checkpoint_min_count: -42,
       subscriber_max_count: 1_500_045,
       named_consumer_strategy: "named_consumer_strategy-16"
     }},
    {:minimal,
     Msg.UpdatePersistentSubscription.new(
       subscription_group_name: "subscription_group_name-1",
       event_stream_id: "event_stream_id-2",
       resolve_link_tos: true,
       start_from: -17_179_869_244,
       message_timeout_milliseconds: 500_015,
       record_statistics: false,
       live_buffer_size: 700_021,
       read_batch_size: -24,
       buffer_size: 900_027,
       max_retry_count: -30,
       prefer_round_robin: true,
       checkpoint_after_time: -36,
       checkpoint_max_count: 1_300_039,
       checkpoint_min_count: -42,
       subscriber_max_count: 1_500_045
     ),
     "0A19737562736372697074696F6E5F67726F75705F6E616D652D3112116576656E745F73747265616D5F69642D32180120C4FFFFFFBFFFFFFFFF0128AFC21E300038F5DC2A40E8FFFFFFFFFFFFFFFF0148BBF73650E2FFFFFFFFFFFFFFFF01580160DCFFFFFFFFFFFFFFFF0168C7AC4F70D6FFFFFFFFFFFFFFFF01788DC75B",
     %{
       buffer_size: 900_027,
       event_stream_id: "event_stream_id-2",
       resolve_link_tos: true,
       subscription_group_name: "subscription_group_name-1",
       start_from: -17_179_869_244,
       message_timeout_milliseconds: 500_015,
       record_statistics: false,
       live_buffer_size: 700_021,
       read_batch_size: -24,
       max_retry_count: -30,
       prefer_round_robin: true,
       checkpoint_after_time: -36,
       checkpoint_max_count: 1_300_039,
       checkpoint_min_count: -42,
       subscriber_max_count: 1_500_045,
       named_consumer_strategy: nil
     }},
    {:full,
     Msg.UpdatePersistentSubscriptionCompleted.new(result: :access_denied, reason: "reason-2"),
     "08031208726561736F6E2D32", %{reason: "reason-2", result: :access_denied}},
    {:minimal, Msg.UpdatePersistentSubscriptionCompleted.new(result: :access_denied), "0803",
     %{reason: nil, result: :access_denied}},
    {:full,
     Msg.WriteEvents.new(
       event_stream_id: "event_stream_id-1",
       expected_version: -8_589_934_622,
       events: [
         Msg.NewEvent.new(
           event_id: <<1, 0, 255, 128, 1>>,
           event_type: "event_type-2",
           data_content_type: 300_009,
           metadata_content_type: -12,
           data: <<5, 0, 255, 128, 5>>,
           metadata: <<6, 0, 255, 128, 6>>
         ),
         Msg.NewEvent.new(
           event_id: <<1, 0, 255, 128, 1>>,
           event_type: "event_type-2",
           data_content_type: 300_009,
           metadata_content_type: -12,
           data: <<5, 0, 255, 128, 5>>,
           metadata: <<6, 0, 255, 128, 6>>
         )
       ],
       require_master: false
     ),
     "0A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A320A050100FF8001120C6576656E745F747970652D3218E9A71220F4FFFFFFFFFFFFFFFF012A050500FF800532050600FF80061A320A050100FF8001120C6576656E745F747970652D3218E9A71220F4FFFFFFFFFFFFFFFF012A050500FF800532050600FF80062000",
     %{
       events: [
         %{
           data: <<5, 0, 255, 128, 5>>,
           metadata: <<6, 0, 255, 128, 6>>,
           data_content_type: 300_009,
           event_id: <<1, 0, 255, 128, 1>>,
           event_type: "event_type-2",
           metadata_content_type: -12
         },
         %{
           data: <<5, 0, 255, 128, 5>>,
           metadata: <<6, 0, 255, 128, 6>>,
           data_content_type: 300_009,
           event_id: <<1, 0, 255, 128, 1>>,
           event_type: "event_type-2",
           metadata_content_type: -12
         }
       ],
       event_stream_id: "event_stream_id-1",
       expected_version: -8_589_934_622,
       require_master: false
     }},
    {:minimal,
     Msg.WriteEvents.new(
       event_stream_id: "event_stream_id-1",
       expected_version: -8_589_934_622,
       require_master: false
     ), "0A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF012000",
     %{
       events: [],
       event_stream_id: "event_stream_id-1",
       expected_version: -8_589_934_622,
       require_master: false
     }},
    {:full,
     Msg.WriteEventsCompleted.new(
       result: :access_denied,
       message: "message-2",
       first_event_number: 12_884_901_933,
       last_event_number: -17_179_869_244,
       prepare_position: 21_474_836_555,
       commit_position: -25_769_803_866,
       current_version: 30_064_771_177
     ),
     "080712096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070",
     %{
       message: "message-2",
       result: :access_denied,
       commit_position: -25_769_803_866,
       prepare_position: 21_474_836_555,
       first_event_number: 12_884_901_933,
       last_event_number: -17_179_869_244,
       current_version: 30_064_771_177
     }},
    {:minimal,
     Msg.WriteEventsCompleted.new(
       result: :access_denied,
       first_event_number: 12_884_901_933,
       last_event_number: -17_179_869_244
     ), "080718AD8080803020C4FFFFFFBFFFFFFFFF01",
     %{
       message: nil,
       result: :access_denied,
       commit_position: nil,
       prepare_position: nil,
       first_event_number: 12_884_901_933,
       last_event_number: -17_179_869_244,
       current_version: nil
     }}
  ]

  @enum_values [
    {Msg.CreatePersistentSubscriptionCompleted, :result, :success, "08001208726561736F6E2D32"},
    {Msg.CreatePersistentSubscriptionCompleted, :result, :already_exists,
     "08011208726561736F6E2D32"},
    {Msg.CreatePersistentSubscriptionCompleted, :result, :fail, "08021208726561736F6E2D32"},
    {Msg.CreatePersistentSubscriptionCompleted, :result, :access_denied,
     "08031208726561736F6E2D32"},
    {Msg.DeletePersistentSubscriptionCompleted, :result, :success, "08001208726561736F6E2D32"},
    {Msg.DeletePersistentSubscriptionCompleted, :result, :does_not_exist,
     "08011208726561736F6E2D32"},
    {Msg.DeletePersistentSubscriptionCompleted, :result, :fail, "08021208726561736F6E2D32"},
    {Msg.DeletePersistentSubscriptionCompleted, :result, :access_denied,
     "08031208726561736F6E2D32"},
    {Msg.DeleteStreamCompleted, :result, :success,
     "080012096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF01"},
    {Msg.DeleteStreamCompleted, :result, :prepare_timeout,
     "080112096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF01"},
    {Msg.DeleteStreamCompleted, :result, :commit_timeout,
     "080212096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF01"},
    {Msg.DeleteStreamCompleted, :result, :forward_timeout,
     "080312096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF01"},
    {Msg.DeleteStreamCompleted, :result, :wrong_expected_version,
     "080412096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF01"},
    {Msg.DeleteStreamCompleted, :result, :stream_deleted,
     "080512096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF01"},
    {Msg.DeleteStreamCompleted, :result, :invalid_transaction,
     "080612096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF01"},
    {Msg.DeleteStreamCompleted, :result, :access_denied,
     "080712096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF01"},
    {Msg.NotHandled, :reason, :not_ready, "080012050200FF8002"},
    {Msg.NotHandled, :reason, :too_busy, "080112050200FF8002"},
    {Msg.NotHandled, :reason, :not_master, "080212050200FF8002"},
    {Msg.PersistentSubscriptionNakEvents, :action, :unknown,
     "0A11737562736372697074696F6E5F69642D3112050200FF800212050200FF80021A096D6573736167652D332000"},
    {Msg.PersistentSubscriptionNakEvents, :action, :park,
     "0A11737562736372697074696F6E5F69642D3112050200FF800212050200FF80021A096D6573736167652D332001"},
    {Msg.PersistentSubscriptionNakEvents, :action, :retry,
     "0A11737562736372697074696F6E5F69642D3112050200FF800212050200FF80021A096D6573736167652D332002"},
    {Msg.PersistentSubscriptionNakEvents, :action, :skip,
     "0A11737562736372697074696F6E5F69642D3112050200FF800212050200FF80021A096D6573736167652D332003"},
    {Msg.PersistentSubscriptionNakEvents, :action, :stop,
     "0A11737562736372697074696F6E5F69642D3112050200FF800212050200FF80021A096D6573736167652D332004"},
    {Msg.ReadAllEventsCompleted, :result, :success,
     "088F8080801010E2FFFFFFDFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF0120C4FFFFFFBFFFFFFFFF0128CB8080805030003A076572726F722D37"},
    {Msg.ReadAllEventsCompleted, :result, :not_modified,
     "088F8080801010E2FFFFFFDFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF0120C4FFFFFFBFFFFFFFFF0128CB8080805030013A076572726F722D37"},
    {Msg.ReadAllEventsCompleted, :result, :error,
     "088F8080801010E2FFFFFFDFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF0120C4FFFFFFBFFFFFFFFF0128CB8080805030023A076572726F722D37"},
    {Msg.ReadAllEventsCompleted, :result, :access_denied,
     "088F8080801010E2FFFFFFDFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF0120C4FFFFFFBFFFFFFFFF0128CB8080805030033A076572726F722D37"},
    {Msg.ReadEventCompleted, :result, :success,
     "080012C8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF011A076572726F722D33"},
    {Msg.ReadEventCompleted, :result, :not_found,
     "080112C8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF011A076572726F722D33"},
    {Msg.ReadEventCompleted, :result, :no_stream,
     "080212C8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF011A076572726F722D33"},
    {Msg.ReadEventCompleted, :result, :stream_deleted,
     "080312C8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF011A076572726F722D33"},
    {Msg.ReadEventCompleted, :result, :error,
     "080412C8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF011A076572726F722D33"},
    {Msg.ReadEventCompleted, :result, :access_denied,
     "080512C8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF011A076572726F722D33"},
    {Msg.ReadStreamEventsCompleted, :result, :success,
     "0AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF010AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF01100018AD8080803020C4FFFFFFBFFFFFFFFF01280130A6FFFFFF9FFFFFFFFF013A076572726F722D37"},
    {Msg.ReadStreamEventsCompleted, :result, :no_stream,
     "0AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF010AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF01100118AD8080803020C4FFFFFFBFFFFFFFFF01280130A6FFFFFF9FFFFFFFFF013A076572726F722D37"},
    {Msg.ReadStreamEventsCompleted, :result, :stream_deleted,
     "0AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF010AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF01100218AD8080803020C4FFFFFFBFFFFFFFFF01280130A6FFFFFF9FFFFFFFFF013A076572726F722D37"},
    {Msg.ReadStreamEventsCompleted, :result, :not_modified,
     "0AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF010AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF01100318AD8080803020C4FFFFFFBFFFFFFFFF01280130A6FFFFFF9FFFFFFFFF013A076572726F722D37"},
    {Msg.ReadStreamEventsCompleted, :result, :error,
     "0AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF010AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF01100418AD8080803020C4FFFFFFBFFFFFFFFF01280130A6FFFFFF9FFFFFFFFF013A076572726F722D37"},
    {Msg.ReadStreamEventsCompleted, :result, :access_denied,
     "0AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF010AC8010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF01100518AD8080803020C4FFFFFFBFFFFFFFFF01280130A6FFFFFF9FFFFFFFFF013A076572726F722D37"},
    {Msg.ScavengeDatabaseCompleted, :result, :success,
     "080012076572726F722D3218E9A71220C4FFFFFFBFFFFFFFFF01"},
    {Msg.ScavengeDatabaseCompleted, :result, :in_progress,
     "080112076572726F722D3218E9A71220C4FFFFFFBFFFFFFFFF01"},
    {Msg.ScavengeDatabaseCompleted, :result, :failed,
     "080212076572726F722D3218E9A71220C4FFFFFFBFFFFFFFFF01"},
    {Msg.SubscriptionDropped, :reason, :unsubscribed, "0800"},
    {Msg.SubscriptionDropped, :reason, :access_denied, "0801"},
    {Msg.SubscriptionDropped, :reason, :not_found, "0802"},
    {Msg.SubscriptionDropped, :reason, :persistent_subscription_deleted, "0803"},
    {Msg.SubscriptionDropped, :reason, :subscriber_max_count_reached, "0804"},
    {Msg.TransactionCommitCompleted, :result, :success,
     "088F8080801010001A096D6573736167652D3320C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.TransactionCommitCompleted, :result, :prepare_timeout,
     "088F8080801010011A096D6573736167652D3320C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.TransactionCommitCompleted, :result, :commit_timeout,
     "088F8080801010021A096D6573736167652D3320C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.TransactionCommitCompleted, :result, :forward_timeout,
     "088F8080801010031A096D6573736167652D3320C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.TransactionCommitCompleted, :result, :wrong_expected_version,
     "088F8080801010041A096D6573736167652D3320C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.TransactionCommitCompleted, :result, :stream_deleted,
     "088F8080801010051A096D6573736167652D3320C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.TransactionCommitCompleted, :result, :invalid_transaction,
     "088F8080801010061A096D6573736167652D3320C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.TransactionCommitCompleted, :result, :access_denied,
     "088F8080801010071A096D6573736167652D3320C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.TransactionStartCompleted, :result, :success, "088F8080801010001A096D6573736167652D33"},
    {Msg.TransactionStartCompleted, :result, :prepare_timeout,
     "088F8080801010011A096D6573736167652D33"},
    {Msg.TransactionStartCompleted, :result, :commit_timeout,
     "088F8080801010021A096D6573736167652D33"},
    {Msg.TransactionStartCompleted, :result, :forward_timeout,
     "088F8080801010031A096D6573736167652D33"},
    {Msg.TransactionStartCompleted, :result, :wrong_expected_version,
     "088F8080801010041A096D6573736167652D33"},
    {Msg.TransactionStartCompleted, :result, :stream_deleted,
     "088F8080801010051A096D6573736167652D33"},
    {Msg.TransactionStartCompleted, :result, :invalid_transaction,
     "088F8080801010061A096D6573736167652D33"},
    {Msg.TransactionStartCompleted, :result, :access_denied,
     "088F8080801010071A096D6573736167652D33"},
    {Msg.TransactionWriteCompleted, :result, :success, "088F8080801010001A096D6573736167652D33"},
    {Msg.TransactionWriteCompleted, :result, :prepare_timeout,
     "088F8080801010011A096D6573736167652D33"},
    {Msg.TransactionWriteCompleted, :result, :commit_timeout,
     "088F8080801010021A096D6573736167652D33"},
    {Msg.TransactionWriteCompleted, :result, :forward_timeout,
     "088F8080801010031A096D6573736167652D33"},
    {Msg.TransactionWriteCompleted, :result, :wrong_expected_version,
     "088F8080801010041A096D6573736167652D33"},
    {Msg.TransactionWriteCompleted, :result, :stream_deleted,
     "088F8080801010051A096D6573736167652D33"},
    {Msg.TransactionWriteCompleted, :result, :invalid_transaction,
     "088F8080801010061A096D6573736167652D33"},
    {Msg.TransactionWriteCompleted, :result, :access_denied,
     "088F8080801010071A096D6573736167652D33"},
    {Msg.UpdatePersistentSubscriptionCompleted, :result, :success, "08001208726561736F6E2D32"},
    {Msg.UpdatePersistentSubscriptionCompleted, :result, :does_not_exist,
     "08011208726561736F6E2D32"},
    {Msg.UpdatePersistentSubscriptionCompleted, :result, :fail, "08021208726561736F6E2D32"},
    {Msg.UpdatePersistentSubscriptionCompleted, :result, :access_denied,
     "08031208726561736F6E2D32"},
    {Msg.WriteEventsCompleted, :result, :success,
     "080012096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.WriteEventsCompleted, :result, :prepare_timeout,
     "080112096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.WriteEventsCompleted, :result, :commit_timeout,
     "080212096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.WriteEventsCompleted, :result, :forward_timeout,
     "080312096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.WriteEventsCompleted, :result, :wrong_expected_version,
     "080412096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.WriteEventsCompleted, :result, :stream_deleted,
     "080512096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.WriteEventsCompleted, :result, :invalid_transaction,
     "080612096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"},
    {Msg.WriteEventsCompleted, :result, :access_denied,
     "080712096D6573736167652D3218AD8080803020C4FFFFFFBFFFFFFFFF0128CB8080805030A6FFFFFF9FFFFFFFFF0138E980808070"}
  ]

  @new_defaults [
    {Msg.ClientIdentified, %{}},
    {Msg.ConnectToPersistentSubscription,
     %{event_stream_id: nil, subscription_id: nil, allowed_in_flight_messages: nil}},
    {Msg.CreatePersistentSubscription,
     %{
       buffer_size: nil,
       event_stream_id: nil,
       resolve_link_tos: nil,
       subscription_group_name: nil,
       start_from: nil,
       message_timeout_milliseconds: nil,
       record_statistics: nil,
       live_buffer_size: nil,
       read_batch_size: nil,
       max_retry_count: nil,
       prefer_round_robin: nil,
       checkpoint_after_time: nil,
       checkpoint_max_count: nil,
       checkpoint_min_count: nil,
       subscriber_max_count: nil,
       named_consumer_strategy: nil
     }},
    {Msg.CreatePersistentSubscriptionCompleted, %{reason: nil, result: :success}},
    {Msg.DeletePersistentSubscription, %{event_stream_id: nil, subscription_group_name: nil}},
    {Msg.DeletePersistentSubscriptionCompleted, %{reason: nil, result: :success}},
    {Msg.DeleteStream,
     %{event_stream_id: nil, expected_version: nil, require_master: nil, hard_delete: nil}},
    {Msg.DeleteStreamCompleted,
     %{message: nil, result: nil, commit_position: nil, prepare_position: nil}},
    {Msg.EventRecord,
     %{
       data: nil,
       metadata: nil,
       data_content_type: nil,
       event_id: nil,
       event_type: nil,
       metadata_content_type: nil,
       event_stream_id: nil,
       event_number: nil,
       created: nil,
       created_epoch: nil
     }},
    {Msg.IdentifyClient, %{version: nil, connection_name: nil}},
    {Msg.NewEvent,
     %{
       data: nil,
       metadata: nil,
       data_content_type: nil,
       event_id: nil,
       event_type: nil,
       metadata_content_type: nil
     }},
    {Msg.NotHandled, %{reason: nil, additional_info: nil}},
    {Msg.NotHandled.MasterInfo,
     %{
       external_tcp_address: nil,
       external_tcp_port: nil,
       external_http_address: nil,
       external_http_port: nil,
       external_secure_tcp_address: nil,
       external_secure_tcp_port: nil
     }},
    {Msg.PersistentSubscriptionAckEvents, %{subscription_id: nil, processed_event_ids: []}},
    {Msg.PersistentSubscriptionConfirmation,
     %{last_event_number: nil, last_commit_position: nil, subscription_id: nil}},
    {Msg.PersistentSubscriptionNakEvents,
     %{message: nil, action: :unknown, subscription_id: nil, processed_event_ids: []}},
    {Msg.PersistentSubscriptionStreamEventAppeared, %{event: nil, retryCount: nil}},
    {Msg.ReadAllEvents,
     %{
       commit_position: nil,
       prepare_position: nil,
       require_master: nil,
       resolve_link_tos: nil,
       max_count: nil
     }},
    {Msg.ReadAllEventsCompleted,
     %{
       error: nil,
       events: [],
       result: :success,
       commit_position: nil,
       prepare_position: nil,
       next_commit_position: nil,
       next_prepare_position: nil
     }},
    {Msg.ReadEvent,
     %{event_stream_id: nil, event_number: nil, require_master: nil, resolve_link_tos: nil}},
    {Msg.ReadEventCompleted, %{error: nil, result: nil, event: nil}},
    {Msg.ReadStreamEvents,
     %{
       event_stream_id: nil,
       require_master: nil,
       resolve_link_tos: nil,
       from_event_number: nil,
       max_count: nil
     }},
    {Msg.ReadStreamEventsBackward,
     %{
       event_stream_id: nil,
       require_master: nil,
       resolve_link_tos: nil,
       from_event_number: nil,
       max_count: nil
     }},
    {Msg.ReadStreamEventsCompleted,
     %{
       error: nil,
       events: [],
       result: nil,
       last_event_number: nil,
       next_event_number: nil,
       is_end_of_stream: nil,
       last_commit_position: nil
     }},
    {Msg.ResolvedEvent, %{link: nil, event: nil, commit_position: nil, prepare_position: nil}},
    {Msg.ResolvedIndexedEvent, %{link: nil, event: nil}},
    {Msg.ScavengeDatabase, %{}},
    {Msg.ScavengeDatabaseCompleted,
     %{error: nil, result: nil, total_time_ms: nil, total_space_saved: nil}},
    {Msg.StreamEventAppeared, %{event: nil}},
    {Msg.SubscribeToStream, %{event_stream_id: nil, resolve_link_tos: nil}},
    {Msg.SubscriptionConfirmation, %{last_event_number: nil, last_commit_position: nil}},
    {Msg.SubscriptionDropped, %{reason: :unsubscribed}},
    {Msg.TransactionCommit, %{require_master: nil, transaction_id: nil}},
    {Msg.TransactionCommitCompleted,
     %{
       message: nil,
       result: nil,
       commit_position: nil,
       prepare_position: nil,
       first_event_number: nil,
       last_event_number: nil,
       transaction_id: nil
     }},
    {Msg.TransactionStart, %{event_stream_id: nil, expected_version: nil, require_master: nil}},
    {Msg.TransactionStartCompleted, %{message: nil, result: nil, transaction_id: nil}},
    {Msg.TransactionWrite, %{events: [], require_master: nil, transaction_id: nil}},
    {Msg.TransactionWriteCompleted, %{message: nil, result: nil, transaction_id: nil}},
    {Msg.UnsubscribeFromStream, %{}},
    {Msg.UpdatePersistentSubscription,
     %{
       buffer_size: nil,
       event_stream_id: nil,
       resolve_link_tos: nil,
       subscription_group_name: nil,
       start_from: nil,
       message_timeout_milliseconds: nil,
       record_statistics: nil,
       live_buffer_size: nil,
       read_batch_size: nil,
       max_retry_count: nil,
       prefer_round_robin: nil,
       checkpoint_after_time: nil,
       checkpoint_max_count: nil,
       checkpoint_min_count: nil,
       subscriber_max_count: nil,
       named_consumer_strategy: nil
     }},
    {Msg.UpdatePersistentSubscriptionCompleted, %{reason: nil, result: :success}},
    {Msg.WriteEvents,
     %{events: [], event_stream_id: nil, expected_version: nil, require_master: nil}},
    {Msg.WriteEventsCompleted,
     %{
       message: nil,
       result: nil,
       commit_position: nil,
       prepare_position: nil,
       first_event_number: nil,
       last_event_number: nil,
       current_version: nil
     }}
  ]

  # protobuf omits an optional field set to its default; exprotobuf wrote it out. Extreme
  # only receives SubscriptionDropped and ReadAllEventsCompleted, and both forms decode alike.
  @omitted_defaults [
    {Msg.SubscriptionDropped, "0800", ""},
    {Msg.ReadAllEventsCompleted,
     "088F8080801010E2FFFFFFDFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF0120C4FFFFFFBFFFFFFFFF0128CB8080805030003A076572726F722D37",
     "088F8080801010E2FFFFFFDFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF011AD9010A620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0112620A116576656E745F73747265616D5F69642D3110E2FFFFFFDFFFFFFFFF011A050300FF8003220C6576656E745F747970652D3428AFC21E30EEFFFFFFFFFFFFFFFF013A050700FF800742050800FF80084887818080900150EAFEFFFFDFFEFFFFFF0118AD8080803020C4FFFFFFBFFFFFFFFF0120C4FFFFFFBFFFFFFFFF0128CB808080503A076572726F722D37"},
    {Msg.ReadAllEventsCompleted,
     "088F8080801010E2FFFFFFDFFFFFFFFF0120C4FFFFFFBFFFFFFFFF0128CB808080503000",
     "088F8080801010E2FFFFFFDFFFFFFFFF0120C4FFFFFFBFFFFFFFFF0128CB80808050"}
  ]
  @protobuf_hex Map.new(@omitted_defaults, fn {_module, exprotobuf_hex, protobuf_hex} ->
                  {exprotobuf_hex, protobuf_hex}
                end)

  @full_messages for {:full, message, _hex, _decoded} <- @messages,
                     into: %{},
                     do: {message.__struct__, message}

  describe "encode/1" do
    for {mode, message, hex, _decoded} <- @messages do
      @message message
      @hex hex
      test "#{inspect(message.__struct__)} #{mode} is byte-identical to exprotobuf" do
        expected = Map.get(@protobuf_hex, @hex, @hex)

        assert expected == @message |> @message.__struct__.encode() |> Base.encode16()
      end
    end

    test "NewEvent data and metadata given as iodata encode like binaries" do
      event =
        Msg.NewEvent.new(
          event_id: "1",
          event_type: "t",
          data_content_type: 0,
          metadata_content_type: 0,
          data: ["a", ["b", ?c]],
          metadata: [<<1>>, "x"]
        )

      binaries = %{event | data: "abc", metadata: <<1, ?x>>}

      assert Msg.NewEvent.encode(binaries) == Msg.NewEvent.encode(event)
      assert _encode_in_write_events(binaries) == _encode_in_write_events(event)
    end
  end

  describe "decode/1" do
    for {mode, message, hex, decoded} <- @messages do
      @module message.__struct__
      @hex hex
      @decoded decoded
      test "#{inspect(message.__struct__)} #{mode} decodes like exprotobuf" do
        assert @decoded == @hex |> Base.decode16!() |> @module.decode() |> _fields()
      end
    end

    test "SubscriptionDropped without a reason decodes to the default reason" do
      assert %{reason: :unsubscribed} = Msg.SubscriptionDropped.decode(<<>>)
    end

    test "ReadAllEventsCompleted without a result decodes to :success" do
      without_result = "088F8080801010E2FFFFFFDFFFFFFFFF0120C4FFFFFFBFFFFFFFFF0128CB80808050"

      assert %{result: :success} =
               without_result |> Base.decode16!() |> Msg.ReadAllEventsCompleted.decode()
    end
  end

  describe "unset submessages" do
    for {module, field} <- [
          {Msg.ResolvedIndexedEvent, :event},
          {Msg.ResolvedIndexedEvent, :link},
          {Msg.ResolvedEvent, :event},
          {Msg.ResolvedEvent, :link},
          {Msg.ReadEventCompleted, :event},
          {Msg.StreamEventAppeared, :event},
          {Msg.PersistentSubscriptionStreamEventAppeared, :event}
        ] do
      @module module
      @field field
      test "#{inspect(module)}.#{field} decodes as nil" do
        assert nil == <<>> |> @module.decode() |> Map.fetch!(@field)
      end
    end

    test "ResolvedIndexedEvent with only a link decodes event as nil" do
      link = @full_messages |> Map.fetch!(Msg.EventRecord) |> Msg.EventRecord.encode()
      only_link = <<0x12>> <> _varint(byte_size(link)) <> link

      assert %{event: nil, link: %Msg.EventRecord{event_type: "event_type-4"}} =
               Msg.ResolvedIndexedEvent.decode(only_link)
    end
  end

  describe "default-valued optional fields" do
    for {{module, exprotobuf_hex, protobuf_hex}, n} <- Enum.with_index(@omitted_defaults) do
      @module module
      @exprotobuf_hex exprotobuf_hex
      @protobuf_hex_value protobuf_hex
      test "#{inspect(module)} #{n} decodes the same with or without the default" do
        assert _decode(@module, @exprotobuf_hex) == _decode(@module, @protobuf_hex_value)
      end
    end
  end

  describe "roundtrip" do
    for {mode, message, _hex, _decoded} <- @messages do
      @message message
      test "#{inspect(message.__struct__)} #{mode} survives encode and decode" do
        module = @message.__struct__

        assert _fields(@message) == @message |> module.encode() |> module.decode() |> _fields()
      end
    end
  end

  describe "enums" do
    for {module, field, value, hex} <- @enum_values do
      @message Map.fetch!(@full_messages, module)
      @field field
      @value value
      @hex hex
      test "#{inspect(module)}.#{field} #{value} keeps its wire value" do
        module = @message.__struct__
        bin = @message |> Map.put(@field, @value) |> module.encode()

        assert Map.get(@protobuf_hex, @hex, @hex) == Base.encode16(bin)
        assert @value == bin |> module.decode() |> Map.fetch!(@field)
      end
    end
  end

  describe "new/0,1" do
    for {module, defaults} <- @new_defaults do
      @module module
      @defaults defaults
      test "#{inspect(module)}.new/0 has exprotobuf's defaults" do
        assert @defaults == _fields(@module.new())
      end
    end

    test "new/1 takes a map as well as a keyword list" do
      assert Msg.SubscribeToStream.new(event_stream_id: "s", resolve_link_tos: true) ==
               Msg.SubscribeToStream.new(%{event_stream_id: "s", resolve_link_tos: true})
    end
  end

  describe "warnings" do
    test "encoding and decoding every message prints nothing in a fresh VM" do
      messages = for {_mode, message, hex, _decoded} <- @messages, do: {message, hex}

      code = """
      for {message, hex} <- #{inspect(messages, limit: :infinity, printable_limit: :infinity)} do
        module = message.__struct__
        module.encode(message)
        hex |> Base.decode16!() |> module.decode()
      end
      """

      build_path = Mix.Project.build_path()

      paths =
        for path <- :code.get_path(),
            path = to_string(path),
            String.starts_with?(path, build_path),
            do: ["-pa", path]

      assert {"", 0} ==
               "elixir"
               |> System.find_executable()
               |> System.cmd(List.flatten(paths) ++ ["-e", code], stderr_to_stdout: true)
    end
  end

  defp _encode_in_write_events(event) do
    [event_stream_id: "s", expected_version: -2, events: [event], require_master: false]
    |> Msg.WriteEvents.new()
    |> Msg.WriteEvents.encode()
  end

  defp _varint(n) when n < 128, do: <<n>>
  defp _varint(n), do: <<1::1, rem(n, 128)::7>> <> _varint(div(n, 128))

  defp _decode(module, hex), do: hex |> Base.decode16!() |> module.decode() |> _fields()

  defp _fields(%{} = struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__unknown_fields__, :__protobuf__])
    |> Map.new(fn {key, value} -> {key, _fields(value)} end)
  end

  defp _fields(values) when is_list(values), do: Enum.map(values, &_fields/1)
  defp _fields(value), do: value
end
