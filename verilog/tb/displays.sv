`include "sys_defs.svh"
package displays;
    logic fail = 0;

    task disp_pass;
        begin
            if (!fail) $write("\033[32;1mPass\033[0;22m\n");
        end
    endtask

    task disp_fail;
        begin
            $write("\033[31;1mFail\033[0;22m\n");
            fail = 1;
        end
    endtask
endpackage
