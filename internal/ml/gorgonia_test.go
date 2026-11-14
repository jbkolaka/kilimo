package ml

import (
	"testing"

	"gorgonia.org/gorgonia"
	"gorgonia.org/tensor"
)

func TestGorgoniaBasic(t *testing.T) {
	g := gorgonia.NewGraph()

	xT := tensor.New(tensor.WithBacking([]float32{1.0, 2.0, 3.0, 4.0}), tensor.WithShape(1, 4))
	x := gorgonia.NewMatrix(g, tensor.Float32, gorgonia.WithShape(1, 4), gorgonia.WithName("x"), gorgonia.WithValue(xT))

	wT := tensor.New(tensor.WithBacking([]float32{
		0.1, 0.2,
		0.3, 0.4,
		0.5, 0.6,
		0.7, 0.8,
	}), tensor.WithShape(4, 2))
	w := gorgonia.NewMatrix(g, tensor.Float32, gorgonia.WithShape(4, 2), gorgonia.WithName("w"), gorgonia.WithValue(wT))

	y, err := gorgonia.Mul(x, w)
	if err != nil {
		t.Fatalf("Mul error: %v", err)
	}

	vm := gorgonia.NewTapeMachine(g)
	defer vm.Close()

	if err := vm.RunAll(); err != nil {
		t.Fatalf("VM run error: %v", err)
	}

	val := y.Value()
	t.Logf("Gorgonia output: %v", val)
}
