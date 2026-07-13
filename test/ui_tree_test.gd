## Validates the preview UI builds correctly by printing the control tree.
extends Node2D

var _ui: RLPreviewUI


func _ready() -> void:
        _ui = RLPreviewUI.new()
        _ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(_ui)
        await get_tree().create_timer(2.0).timeout
        # Print aggregate stats labels to verify they're updating
        print("=== Stats panel values ===")
        var stats_panel: VBoxContainer = _ui._stats_panel
        for child in stats_panel.get_children():
                if child is HBoxContainer:
                        var labels: Array = child.get_children()
                        if labels.size() >= 2:
                                print("  %s = %s" % [labels[0].text, labels[1].text])
        get_tree().quit()


func _print_tree_summary(node: Node, depth: int = 0) -> void:
        var indent := "  ".repeat(depth)
        var info := indent + node.name + " (" + node.get_class()
        if node is Control:
                var c := node as Control
                info += " size=%s" % str(c.size)
                if c.size_flags_horizontal & Control.SIZE_EXPAND_FILL:
                        info += " [H_EXPAND]"
                if c.size_flags_vertical & Control.SIZE_EXPAND_FILL:
                        info += " [V_EXPAND]"
        info += ")"
        print(info)
        for child in node.get_children():
                _print_tree_summary(child, depth + 1)
