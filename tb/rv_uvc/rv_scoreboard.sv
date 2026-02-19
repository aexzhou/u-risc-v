// RISC-V Scoreboard
// Checks DUT outputs against expected results

`ifndef RISCV_SCOREBOARD_SV
`define RISCV_SCOREBOARD_SV

class riscv_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(riscv_scoreboard)

    uvm_analysis_imp#(riscv_transaction, riscv_scoreboard) ap_imp;

    // Statistics
    int transactions_received;
    int transactions_passed;
    int transactions_failed;

    // Reference register file for expected values
    bit [63:0] ref_regs [0:31];

    function new(string name = "riscv_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        transactions_received = 0;
        transactions_passed = 0;
        transactions_failed = 0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp", this);

        // Initialize reference registers
        for (int i = 0; i < 32; i++) begin
            ref_regs[i] = 64'h0;
        end
    endfunction

    virtual function void write(riscv_transaction txn);
        transactions_received++;

        `uvm_info(get_type_name(),
                 $sformatf("Received transaction #%0d: %s",
                           transactions_received, txn.convert2string()),
                 UVM_MEDIUM)

        // Decode and check instruction
        check_instruction(txn);
    endfunction

    virtual function void check_instruction(riscv_transaction txn);
        bit [6:0] opcode;
        bit [4:0] rd, rs1, rs2;
        bit [2:0] funct3;
        bit [6:0] funct7;
        bit [63:0] expected_value;
        bit check_passed;

        opcode = txn.instruction[6:0];
        rd = txn.instruction[11:7];
        rs1 = txn.instruction[19:15];
        rs2 = txn.instruction[24:20];
        funct3 = txn.instruction[14:12];
        funct7 = txn.instruction[31:25];

        check_passed = 1;

        case (opcode)
            7'b0010011: begin // I-type (addi, etc.)
                bit [11:0] imm;
                bit [63:0] imm_ext;
                imm = txn.instruction[31:20];
                imm_ext = {{52{imm[11]}}, imm}; // Sign extend

                case (funct3)
                    3'b000: begin // addi
                        expected_value = ref_regs[rs1] + imm_ext;
                        `uvm_info(get_type_name(),
                                 $sformatf("ADDI x%0d, x%0d, %0d (x%0d=%0d + %0d = %0d)",
                                           rd, rs1, $signed(imm_ext), rd,
                                           ref_regs[rs1], $signed(imm_ext), expected_value),
                                 UVM_LOW)
                    end
                    default: expected_value = 64'hx;
                endcase

                if (rd != 0) ref_regs[rd] = expected_value;
            end

            7'b0110011: begin // R-type (add, sub, etc.)
                case ({funct7, funct3})
                    10'b0000000_000: begin // add
                        expected_value = ref_regs[rs1] + ref_regs[rs2];
                        `uvm_info(get_type_name(),
                                 $sformatf("ADD x%0d, x%0d, x%0d (%0d + %0d = %0d)",
                                           rd, rs1, rs2,
                                           ref_regs[rs1], ref_regs[rs2], expected_value),
                                 UVM_LOW)
                    end
                    10'b0100000_000: begin // sub
                        expected_value = ref_regs[rs1] - ref_regs[rs2];
                        `uvm_info(get_type_name(),
                                 $sformatf("SUB x%0d, x%0d, x%0d (%0d - %0d = %0d)",
                                           rd, rs1, rs2,
                                           ref_regs[rs1], ref_regs[rs2], expected_value),
                                 UVM_LOW)
                    end
                    10'b0000000_111: begin // and
                        expected_value = ref_regs[rs1] & ref_regs[rs2];
                        `uvm_info(get_type_name(),
                                 $sformatf("AND x%0d, x%0d, x%0d", rd, rs1, rs2),
                                 UVM_LOW)
                    end
                    10'b0000000_110: begin // or
                        expected_value = ref_regs[rs1] | ref_regs[rs2];
                        `uvm_info(get_type_name(),
                                 $sformatf("OR x%0d, x%0d, x%0d", rd, rs1, rs2),
                                 UVM_LOW)
                    end
                    default: expected_value = 64'hx;
                endcase

                if (rd != 0) ref_regs[rd] = expected_value;
            end

            default: begin
                `uvm_info(get_type_name(),
                         $sformatf("Unknown opcode: 0x%0h", opcode),
                         UVM_LOW)
            end
        endcase

        if (check_passed)
            transactions_passed++;
        else
            transactions_failed++;
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info(get_type_name(), "========== SCOREBOARD REPORT ==========", UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Transactions Received: %0d", transactions_received), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Transactions Passed:   %0d", transactions_passed), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Transactions Failed:   %0d", transactions_failed), UVM_NONE)

        `uvm_info(get_type_name(), "Final Register File:", UVM_NONE)
        for (int i = 0; i < 32; i++) begin
            if (ref_regs[i] != 0) begin
                `uvm_info(get_type_name(), $sformatf("  x%0d = 0x%0h (%0d)", i, ref_regs[i], ref_regs[i]), UVM_NONE)
            end
        end

        `uvm_info(get_type_name(), "=======================================", UVM_NONE)

        if (transactions_failed > 0)
            `uvm_error(get_type_name(), "TEST FAILED!")
        else if (transactions_received > 0)
            `uvm_info(get_type_name(), "TEST PASSED!", UVM_NONE)
    endfunction

endclass

`endif // RISCV_SCOREBOARD_SV
