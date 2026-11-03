# Testing

## Suite Setup

```go
// Bad — plain testify suite
import "github.com/stretchr/testify/suite"
import "github.com/stretchr/testify/assert"

// Good
import "github.com/Khan/webapp/dev/khantest"

type MyTestSuite struct {
	khantest.Suite
}

func TestMyTestSuite(t *testing.T) {
	khantest.Run(t, &MyTestSuite{})
}
```

## Assertions (`ka-suite`)

```go
// Outside All() — use Require (fails fast)
func (suite *MyTestSuite) TestFoo() {
	result, err := doThing("input")
	suite.Require().NoError(err) // not suite.Assert()
	suite.Require().NotNil(result)

	// Multiple soft assertions — use All
	suite.All(
		suite.Assert().Equal(expected, result.Name),
		suite.Assert().Equal(42, result.Count))
}
```

`All` is `All(assertions ...bool)`. It takes the **results** of assertions that
have already run — `suite.Assert().Equal(...)` returns a bool — so passing it a
closure is a compile error. It reports every failure, then calls `FailNow`.

`khantest.Suite` has no context accessor; it is for pure logic that needs no
`KAContext`. Anything needing one belongs on `servicetest.Suite`, whose
`suite.KAContext()` returns a `kacontext.TestContext`.

Do **not** use `suite.Nil(err)` for errors — use `suite.Require().NoError(err)`.

## Lifecycle Methods Must Call Super

```go
func (suite *MyTestSuite) SetupSuite() {
	suite.Suite.SetupSuite() // required

	// your setup here
}

func (suite *MyTestSuite) TearDownTest() {
	suite.Suite.TearDownTest() // required
}
```

## Environment Variables in Tests

```go
// Bad
os.Setenv("MY_FLAG", "true")

// Good
suite.Setenv("MY_FLAG", "true") // automatically cleaned up
```
