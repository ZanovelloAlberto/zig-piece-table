const std = @import("std");

const a = struct { pi: usize, bo: usize };
const pieceTable = struct {
    const Self = @This();
    original: []const u8, // original contents
    add: std.ArrayList(u8), // user added contents
    nodes: std.ArrayList(Node),

    pub fn init(self: *Self, origin: []const u8, all: std.mem.Allocator) !void {
        self.original = origin;
        self.nodes = std.ArrayList(Node).init(all);
        try self.nodes.append(Node{
            .addBuffer = false,
            .offset = 0,
            .lenght = origin.len,
            // .lineStart = std.ArrayList(usize).init(all),
        });
        self.add = std.ArrayList(u8).init(all);
    }

    fn searchPiece(self: *Self, offset: usize, res: *a) !void {
        if (offset < 0) {
            error.outOfBounds;
        }
        var remaningOffset = offset;
        for (self.nodes.items) |piece, i| {
            if (remaningOffset <= piece.lenght) {
                res.pi = i;
                res.bo = piece.offset + remaningOffset;
                return;
            }
            remaningOffset -= piece.lenght;
        }
        return error.outOfBounds;
    }
    pub fn insert(self: *Self, str: []const u8, offset: usize) !void {
        if (str.len == 0) return;
        const addBufferedOffset = self.add.items.len;
        try self.add.appendSlice(str);
        var sq: a = a{
            .pi = 0,
            .bo = 0,
        };
        try self.searchPiece(offset, &sq);
        var originalPiece: Node = self.nodes.items[sq.pi];
        //
        if (originalPiece.addBuffer and sq.bo == originalPiece.offset and originalPiece.offset + originalPiece.lenght == addBufferedOffset) {
            originalPiece.lenght += str.len;
            return;
        }
        var pri = sq.bo - originalPiece.offset;
        var ter = originalPiece.lenght - (sq.bo - originalPiece.offset);
        // primo nodo
        var primo = Node{
            .addBuffer = originalPiece.addBuffer,
            .offset = originalPiece.offset,
            .lenght = pri,
        };
        var secondo = Node{
            .addBuffer = true,
            .offset = addBufferedOffset,
            .lenght = str.len,
        };

        var terzo = Node{
            .addBuffer = originalPiece.addBuffer,
            .offset = sq.bo,
            .lenght = ter,
        };

        try self.nodes.replaceRange(
            sq.pi,
            1,
            if (pri > 0 and ter > 0) &[_]Node{ primo, secondo, terzo } else if (ter > 0) &[_]Node{ secondo, terzo } else &[_]Node{ primo, secondo },
        );
    }
    pub fn delete(self: *Self, offset: usize, lenght: usize) !void {
        if (lenght == 0) return;
        if (offset < 0) error.OutOfBounds;
        var ini = a{
            .pi = 0,
            .bo = 0,
        };
        var final = a{
            .pi = 0,
            .bo = 0,
        };
        try self.searchPiece(offset, &ini);
        try self.searchPiece(offset + lenght, &final);

        if (ini.pi == final.pi) {
            var piece = self.nodes.items[ini.pi];

            if (ini.bo == piece.offset) {
                piece.offset += lenght;
                piece.lenght -= lenght;
                return;
            } else if (final.bo == piece.offset + piece.lenght) {
                piece.lenght -= lenght;
                return;
            }
        }

        try self.nodes.replaceRange(ini.pi, final.pi - ini.pi + 1, &[_]Node{
            Node{
                .addBuffer = self.nodes.items[ini.pi].addBuffer,
                .offset = self.nodes.items[ini.pi].offset,
                .lenght = ini.bo - self.nodes.items[ini.pi].offset,
            },
            Node{
                .addBuffer = self.nodes.items[ini.pi].addBuffer,
                .offset = final.bo,
                .lenght = self.nodes.items[final.pi].lenght - (final.bo - self.nodes.items[final.pi].offset),
            },
        });
    }

    pub fn getSequence(self: *Self) !std.ArrayList(u8) {
        var res = std.ArrayList(u8).init(std.heap.page_allocator);

        for (self.nodes.items) |piece| {
            if (piece.addBuffer) {
                try res.appendSlice(self.add.items[piece.offset .. piece.lenght + piece.offset]);
            } else {
                try res.appendSlice(self.original[piece.offset .. piece.lenght + piece.offset]);
            }
        }
        return res;
    }
};
var table: pieceTable = undefined;

const Node = struct {
    // type: NodeType,
    offset: usize,
    addBuffer: bool,
    lenght: usize,
    // lineStart: std.ArrayList(usize),
};

// const NodeType = enum { Original, Added };

pub fn readFileToBuf(path: *const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf = try file.readToEndAlloc(std.heap.page_allocator, 99999);
    return buf;
}
test {
    // var uno: [100]u8 = undefined;
    // var due = &[_]u8{ 1, 2, 3, 4, 3, 1, 2, 2 };

    // var arrt = std.ArrayList(u8).init(std.testing.allocator);
    // try arrt.appendSlice(due[1..5]);
}

test "testo_data_struct" {
    const ori =
        \\provando uno
    ;
    try table.init(ori, std.heap.page_allocator);
    try table.insert("CIAOO", 2);
    try table.insert("XX", 12);
    try table.delete(12, 2);
    var arr = try table.getSequence();
    std.debug.print("\nthis:{s}\n", .{table.add.items});
    std.debug.print("\nthis:{s}\n", .{table.original});
    std.debug.print("\nthis:{}\n", .{table.nodes.items.len});
    std.debug.print("\nthis:{s}\n", .{arr.items});

    for (table.nodes.items) |value| {
        std.debug.print(" - {}\n", .{value});
    }
    // try std.testing.expect(table.nodes.items.len == 3);
    // try std.testing.expect(table.nodes.items[0].lenght == table.original.len);
    // std.ArrayList(u8).in
    // var b = std.SinglyLinkedList(u8);
}
