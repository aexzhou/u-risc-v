class clk_rst_driver extends uvm_driver #(clk_rst_seq_item);

    `uvm_component_utils(clk_rst_driver)

    virtual clk_rst_if vif;

    // Pending count-clock requests sorted by remaining cycles.
    // Each entry's clock_cycles_to_count holds a *relative* delta
    // (cycles until this entry expires after the previous one).
    clk_rst_seq_item count_clocks_request_queue[$];

    function new(string name = "clk_rst_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (!uvm_config_db #(virtual clk_rst_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
    endfunction

    // ============================================================
    //  Main run phase
    // ============================================================
    virtual task run_phase(uvm_phase phase);
        fork
            process_count_clocks_responses();
        join_none

        forever begin
            seq_item_port.get(req);
            case (req.req_type)
                clk_rst_seq_item::START_CLOCK: begin
                    if (req.clock_period < 2)
                        `uvm_fatal(get_type_name(),
                            $sformatf("clock_period must be >= 2, got %0d", req.clock_period))
                    `uvm_info(get_type_name(),
                        $sformatf("START_CLOCK: period=%0d rst_dly=%0d run=%0b",
                                  req.clock_period, req.reset_delay, req.run_clock), UVM_LOW)
                    vif.start_clock(req.clock_period, req.reset_delay, req.run_clock);
                end

                clk_rst_seq_item::STOP_CLOCK: begin
                    `uvm_info(get_type_name(), "STOP_CLOCK", UVM_LOW)
                    vif.stop_clock();
                end

                clk_rst_seq_item::ASSERT_RESET: begin
                    `uvm_info(get_type_name(), "ASSERT_RESET", UVM_LOW)
                    vif.assert_reset();
                end

                clk_rst_seq_item::DEASSERT_RESET: begin
                    `uvm_info(get_type_name(), "DEASSERT_RESET", UVM_LOW)
                    vif.deassert_reset();
                end

                clk_rst_seq_item::COUNT_CLOCKS: begin
                    `uvm_info(get_type_name(),
                        $sformatf("COUNT_CLOCKS: %0d cycles", req.clock_cycles_to_count), UVM_LOW)
                    queue_count_clock_request(req);
                end

                default: begin
                    `uvm_error(get_type_name(),
                        $sformatf("Unknown req_type: %s", req.req_type.name()))
                end
            endcase
        end
    endtask

    // ============================================================
    //  Count-clock request queue management
    //
    //  Maintains a sorted delta-queue so that overlapping delay
    //  requests from multiple sequences are served in order.
    //
    //  Each queued item stores a *relative* count: the number of
    //  cycles between the previous item's expiration and its own.
    //  The interface countdown is always loaded with the front
    //  item's delta.
    //
    //  Example:
    //    Absolute requests  10, 40, 41  =>  queue deltas {10, 30, 1}
    //    Insert request 19              =>  queue deltas {10, 9, 21, 1}
    //    Insert request 61              =>  queue deltas {10, 9, 21, 1, 20}
    // ============================================================
    virtual task queue_count_clock_request(
        input clk_rst_seq_item clock_count_req
    );
        clk_rst_seq_item item_to_queue;

        // Clone so the queued copy is independent of the sequence's handle
        item_to_queue = clk_rst_seq_item::type_id::create("item_to_queue");
        $cast(item_to_queue, clock_count_req.clone());
        item_to_queue.set_id_info(clock_count_req);

        if (count_clocks_request_queue.size() == 0) begin
            // First request - load the interface counter directly
            vif.count_clocks(item_to_queue.clock_cycles_to_count);
            `uvm_info(get_type_name(),
                $sformatf("New delay of %0d arrived, starting delay counter",
                          item_to_queue.clock_cycles_to_count), UVM_LOW)
            count_clocks_request_queue.push_front(item_to_queue);
        end
        else begin
            int total_clock_cycles_to_count = 0;
            int current_cycle_count;

            // Snapshot the interface's remaining count into queue[0]
            vif.get_current_cycle_count(current_cycle_count);
            count_clocks_request_queue[0].clock_cycles_to_count = current_cycle_count;

            if (item_to_queue.clock_cycles_to_count < current_cycle_count) begin
                // New request expires sooner than current front - push to front
                count_clocks_request_queue.push_front(item_to_queue);
                count_clocks_request_queue[1].clock_cycles_to_count =
                    current_cycle_count - item_to_queue.clock_cycles_to_count;
                vif.count_clocks(item_to_queue.clock_cycles_to_count);
                `uvm_info(get_type_name(),
                    $sformatf("New shorter count of %0d arrived, restarting delay counter",
                              item_to_queue.clock_cycles_to_count), UVM_LOW)
            end
            else if (item_to_queue.clock_cycles_to_count == current_cycle_count) begin
                // Expires at the same time as current front - insert with delta 0
                item_to_queue.clock_cycles_to_count = 0;
                count_clocks_request_queue.push_front(item_to_queue);
            end
            else begin
                // Walk the queue and insert at the correct sorted position
                for (int idx = 0; idx < count_clocks_request_queue.size(); idx++) begin
                    if (item_to_queue.clock_cycles_to_count > total_clock_cycles_to_count &&
                        item_to_queue.clock_cycles_to_count <
                            total_clock_cycles_to_count +
                            count_clocks_request_queue[idx].clock_cycles_to_count
                    ) begin
                        item_to_queue.clock_cycles_to_count -= total_clock_cycles_to_count;
                        count_clocks_request_queue.insert(idx, item_to_queue);
                        count_clocks_request_queue[idx+1].clock_cycles_to_count -=
                            item_to_queue.clock_cycles_to_count;
                        break;
                    end
                    else if (idx == count_clocks_request_queue.size() - 1) begin
                        if (item_to_queue.clock_cycles_to_count <
                            count_clocks_request_queue[$].clock_cycles_to_count
                        ) begin
                            item_to_queue.clock_cycles_to_count -= total_clock_cycles_to_count;
                            count_clocks_request_queue.insert(idx, item_to_queue);
                            count_clocks_request_queue[$].clock_cycles_to_count -=
                                item_to_queue.clock_cycles_to_count;
                        end
                        else begin
                            total_clock_cycles_to_count +=
                                count_clocks_request_queue[idx].clock_cycles_to_count;
                            item_to_queue.clock_cycles_to_count -= total_clock_cycles_to_count;
                            count_clocks_request_queue.push_back(item_to_queue);
                        end
                        break;
                    end
                    total_clock_cycles_to_count +=
                        count_clocks_request_queue[idx].clock_cycles_to_count;
                end
            end
        end

        // Debug: dump queue state
        for (int idx = 0; idx < count_clocks_request_queue.size(); idx++) begin
            `uvm_info(get_type_name(),
                $sformatf("  queue[%0d].delta = %0d", idx,
                          count_clocks_request_queue[idx].clock_cycles_to_count),
                UVM_HIGH)
        end
    endtask

    // ============================================================
    //  Countdown expiration handler
    //
    //  Waits for the interface's clock_cycle_count_reached event,
    //  pops the front item, sends the response back to the
    //  originating sequence, and loads the next delta if any.
    // ============================================================
    virtual task process_count_clocks_responses();
        clk_rst_seq_item rsp_item;
        forever begin
            @(vif.clock_cycle_count_reached);
            `uvm_info(get_type_name(),
                "Delay counter reached 0, returning item from queue", UVM_HIGH)

            rsp_item = count_clocks_request_queue.pop_front();
            seq_item_port.put(rsp_item);

            // Drain any queued items with delta == 0, then load the next
            while (count_clocks_request_queue.size() != 0) begin
                if (count_clocks_request_queue[0].clock_cycles_to_count != 0) begin
                    vif.count_clocks(
                        count_clocks_request_queue[0].clock_cycles_to_count);
                    `uvm_info(get_type_name(),
                        $sformatf("Next queued delay of %0d, starting counter",
                                  count_clocks_request_queue[0].clock_cycles_to_count),
                        UVM_HIGH)
                    break;
                end
                else begin
                    `uvm_info(get_type_name(),
                        "Popping zero-delta item from queue", UVM_HIGH)
                    rsp_item = count_clocks_request_queue.pop_front();
                    seq_item_port.put(rsp_item);
                end
            end
        end
    endtask

    // ============================================================
    //  Report phase - flag outstanding must-happen counts
    // ============================================================
    virtual function void report_phase(uvm_phase phase);
        int must_happen_count = 0;

        if (count_clocks_request_queue.size() != 0) begin
            `uvm_info(get_type_name(),
                "count_clocks_request_queue not empty at end of simulation - "
                , UVM_LOW)
            foreach (count_clocks_request_queue[i]) begin
                if (count_clocks_request_queue[i].cycle_count_must_happen)
                    must_happen_count++;
            end
            if (must_happen_count > 0) begin
                `uvm_error(get_type_name(),
                    $sformatf("%0d outstanding count(s) had cycle_count_must_happen set",
                              must_happen_count))
            end
        end
    endfunction

endclass : clk_rst_driver
